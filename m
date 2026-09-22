From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 22 Sep 2026 11:08:13 +0200
Subject: [PATCH] ipvs: skip committing sync_threshold when proc_dointvec
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260922-lklm-sysctl-retval-fix-v1-1-7290ea4253a4@kernel.org>
X-B4-Tracking: v=1; b=H4sIAHxFsmoC/x2M2wpAQBBAf0XzbIpRxK/Iw9odTNalHYnk320ez
 6lzHlAOwgpN8kDgU1S2NUKeJmAns46M4iIDZVRmNRH62S+ot9rDY+DjNB4HudD0xlHtbFH1DmK
 8B476H7fd+350fIRlaAAAAA==
X-Change-ID: 20260922-lklm-sysctl-retval-fix-abad29dc37bd
To: Simon Horman <horms@verge.net.au>, Julian Anastasov <ja@ssi.bg>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>
Cc: Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 lvs-devel@vger.kernel.org, netfilter-devel@vger.kernel.org, 
 coreteam@netfilter.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1296;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=aWEqlZnVkFRgp0qQKu7X23kGg0ZHVehrYng8L//OeY0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGqyRZGUA0KCGTVtlF++nMgUcIdQrRiZq3RUU
 /YgHZ0t3bnNBokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqskWRAAoJELqXzVK3
 lkFPDmYMAJI5M0li0IFDoGjBI7dEFL6+2/SLWT6ezLqZGKpiiRPP3nCorSqTS0ybmW666HQuCL5
 dl+yPbeZ7QhF6ret88F/aAbXd0D24GHNSsgns1igp2JdZSpfgJWVFwYXed3twvuH8C7ZOlkpwTY
 q1MDtTpBcHHo3iasIgrhs3ve760S3aEWRFx0m5t1X1HsiBqF0OPl/4E4A/0D/lKXV3Xll3mhnSA
 zH+0b2/bmW/N68hXf1BeUgxPRQzrejpqiGy+VTMxfT/XF0fvpktRdIaDPyOeFVRvIfLX+gkPl8b
 qjWI21hUbFwmQUmDe+gJ1A743mX4qpKw+PuIcR9xo/hk0P3pN05i4WcBUhtfinx7cYQTmjRwZrh
 9//gOU3degccRS6r4Ot/Qqyb3+EX0RtqReRilJAdaB5Kvx46ukpCnBvX8vuYHKfDoc2wXLjiOQg
 S/GVKugi5BLDPXCSqC1jArJQzeBwgwu7Z11zRLwTe70gaQiOU+S7nkCHMrYk9fTuS93/sayKDF5
 do=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Forward rc value and skip updating sysctl_sync_threshold when
proc_dointvec fails. This targets a write such as "5 x" which would fail
with -EINVAL but would store the first element anyway.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 net/netfilter/ipvs/ip_vs_ctl.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/net/netfilter/ipvs/ip_vs_ctl.c b/net/netfilter/ipvs/ip_vs_ctl.c
index 4c1c739446b76ea455dab2958a844d05e31a46a7..7c260529238cd2015f1d30abd094d25b056b30fa 100644
--- a/net/netfilter/ipvs/ip_vs_ctl.c
+++ b/net/netfilter/ipvs/ip_vs_ctl.c
@@ -2454,6 +2454,8 @@ proc_do_sync_threshold(const struct ctl_table *table, int write,
 	mutex_lock(&ipvs->sync_mutex);
 	memcpy(val, valp, sizeof(val));
 	rc = proc_dointvec(&tmp, write, buffer, lenp, ppos);
+	if (rc)
+		goto out;
 	if (write) {
 		if (val[0] < 0 || val[1] < 0 ||
 		    (val[0] >= val[1] && val[1]))
@@ -2461,6 +2463,7 @@ proc_do_sync_threshold(const struct ctl_table *table, int write,
 		else
 			memcpy(valp, val, sizeof(val));
 	}
+out:
 	mutex_unlock(&ipvs->sync_mutex);
 	return rc;
 }

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260922-lklm-sysctl-retval-fix-abad29dc37bd

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

