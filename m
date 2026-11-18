From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Nov 2026 14:44:44 +0100
Subject: [PATCH] sysctl: Do jiffy / ms conversion in ulong space
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-lklm-sysctl-jiffie-ms-conv-v1-1-bb60e5101418@kernel.org>
X-B4-Tracking: v=1; b=H4sIAMur/WoC/x3MQQ6DIBAAwK+YPXcTIFWhX2k8tLjUtQiGbUwb4
 98lPc5ldhAqTAK3ZodCGwvnVKEvDfjpkV6EPFaDUabTWluM77ig/MR/Is4cAhMugj6nDXtln66
 ja+sUQQ3WQoG///w+HMcJND1T6GwAAAA=
X-Change-ID: 20261118-lklm-sysctl-jiffie-ms-conv-708b96e4590e
To: Avi Weiss <thnkslprpt@gmail.com>
Cc: Kees Cook <kees@kernel.org>, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4096;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=cvT9Z1VwMr5AX7VWBnNxERQBI/gspsX2d3xpiXPpo3Q=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGr9q9522ph5NaWuU0hIWdArP19DxUNdXP699
 FB56xaJCfvkK4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJq/aveAAoJELqXzVK3
 lkFPRLoL/2iGsdd2cbRQjQh4Mzx7Kiw4PFkv0Mfy8fSgX4DH/DRLhGfUwNKif6JF5OzIjZ3I6ZE
 kGJ7RmYmVdm/flBjtcKWCxx8tBnANZlrk2vTmV6Oz8MqGY/F2hvvWDzusEZBlmh0gRhQwHbDYp7
 W3OHeheyPK/4X0W/OTLVRQX98XjvY+JGS7JksTNQ7s9AS/MioQqTpreB+hdOlnDTzFccVhGjs8/
 eSnAvxFUHhC/mJb08J53s86jMbR7VQJV+MMkKnWR/hL0OVOixINCJ4Jpsacc4qVzrnh1RW+XUEu
 JvS1uRN27aZlOvl8Z68ZEpyog1KvJB4qfJH60se+UayrpngQxEhvuu2MY4nHjRCEBHLS257s6tM
 1u6MaadNWLPpm7eRtcgm1bQDuC7LG9GVA8GqCXry6UtIcyYuEaFtqZk0+0X3iKRO4/nRVculuje
 d3DG5Z8Sv7iyxKsaBGzqUHi6Ibg9GLdjvsHLJ+t1fAaufiPCgMhtzrvKl/l+XJwysDjy1AUGhc8
 v4=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace jiffies_to_msecs & msecs_to_jiffies calls with sysctl specific
converters. Removes the need to handle overflow corner cases when moving
to and from the unsigned int and the unsigned long spaces.

Handle the unsigned long overflow in the sysctl specific converters
(sysctl_jiffies_to_msecs & sysctl_msecs_to_jiffies). The unsigned int
overflow is handled in the generic sysctl int converters (e.g.
proc_int_u2k_conv_uop).

Round up on writes and down on reads for both unsigned int and unsigned
long types.

This is the behavior being fixed:

SUL="/proc/sys/net/rxrpc/idle_conn_fast_expiry"
SSI="/proc/sys/debug/test_sysctl/int_ms_jiffies"

1. Before
    # HZ = 300, CONFIG_TEST_SYSCTL=y & CONFIG_AF_RXRPC=y
    echo 1 > $SSI; cat $SSI           # -> 4
    echo 4 > $SSI; cat $SSI           # -> 7
    echo 7 > $SSI; cat $SSI           # -> 10
    echo 10 > $SSI; cat $SSI          # -> 10

    echo 4 > $SUL; cat $SUL           # -> 3
    echo 3 > $SUL; cat $SUL           # echo: write error: Invalid argument

    # HZ = 100, CONFIG_TEST_SYSCTL=y & CONFIG_AF_RXRPC=y
    echo 2147483648 > $SUL; cat $SUL  # -> 4294967276
    echo 5000000000 > $SUL; cat $SUL  # -> 4294967276

2. Now
    # HZ = 300, CONFIG_TEST_SYSCTL=y & CONFIG_AF_RXRPC=y
    echo 1 > $SSI; cat $SSI           # -> 3
    echo 3 > $SSI; cat $SSI           # -> 3
    echo 4 > $SSI; cat $SSI           # -> 6
    echo 6 > $SSI; cat $SSI           # -> 6
    echo 7 > $SSI; cat $SSI           # -> 10
    echo 10 > $SSI; cat $SSI          # -> 10

    echo 4 > $SUL; cat $SUL           # -> 6
    echo 6 > $SUL; cat $SUL           # -> 6

    # HZ = 100, CONFIG_TEST_SYSCTL=y & CONFIG_AF_RXRPC=y
    echo 2147483648 > $SUL; cat $SUL  # -> 2147483650
    echo 5000000000 > $SUL; cat $SUL  # -> 5000000000

Fixes: afdf35cfae0d ("sysctl: Fix type truncation in sysctl_msec_to_jiffies")
Fixes: b96b5c6708ea ("sysctl: Replace do_proc_do{int,ulong,uint}vec with do_proc_vec")

Reported-by: Avi Weiss <thnkslprpt@gmail.com>
Link: https://lore.kernel.org/all/20261102111516.1398262-2-thnkslprpt@gmail.com
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Avi:

This is how it will be upstreamed. In case you have any opinions.

Best
---
 kernel/time/jiffies.c | 21 +++++++++++++++++----
 1 file changed, 17 insertions(+), 4 deletions(-)

diff --git a/kernel/time/jiffies.c b/kernel/time/jiffies.c
index af1c69bf0c23dbcf1788e951dd9872167388bd1c..b861dc860d3452b59868128ec83340eab9e18a39 100644
--- a/kernel/time/jiffies.c
+++ b/kernel/time/jiffies.c
@@ -137,11 +137,19 @@ static int sysctl_k2u_int_conv_userhz(bool *negp, ulong *u_ptr, const int *k_ptr
 	return proc_int_k2u_conv_kop(u_ptr, k_ptr, negp, sysctl_jiffies_to_clock_t);
 }
 
+/*
+ * Calc ms <-> jiffies conversions for sysctls in unsigned long arithmetic.
+ * Think hard about using the non-sysctl converters (msecs_to_jiffies &
+ * jiffies_to_msecs) as the interaction between ulong and uint is not trivial.
+ */
 static ulong sysctl_msecs_to_jiffies(const ulong val)
 {
-	if (val > jiffies_to_msecs(MAX_JIFFY_OFFSET))
-		return MAX_JIFFY_OFFSET;
-	return msecs_to_jiffies(val);
+	ulong secs = val / MSEC_PER_SEC;
+
+	if (secs >= ULONG_MAX / HZ)
+		return ULONG_MAX;
+
+	return secs * HZ + DIV_ROUND_UP((val % MSEC_PER_SEC) * HZ, MSEC_PER_SEC);
 }
 
 static int sysctl_u2k_int_conv_ms(const bool *negp, const ulong *u_ptr, int *k_ptr)
@@ -151,7 +159,12 @@ static int sysctl_u2k_int_conv_ms(const bool *negp, const ulong *u_ptr, int *k_p
 
 static ulong sysctl_jiffies_to_msecs(const ulong val)
 {
-	return jiffies_to_msecs(val);
+	ulong secs = val / HZ;
+
+	if (secs >= ULONG_MAX / MSEC_PER_SEC)
+		return ULONG_MAX;
+
+	return secs * MSEC_PER_SEC + (val % HZ) * MSEC_PER_SEC / HZ;
 }
 
 static int sysctl_k2u_int_conv_ms(bool *negp, ulong *u_ptr, const int *k_ptr)

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261118-lklm-sysctl-jiffie-ms-conv-708b96e4590e

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

