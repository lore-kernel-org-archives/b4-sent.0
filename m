From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 29 Sep 2025 17:55:07 +0200
Subject: [PATCH] watchdog: move nmi_watchdog sysctl into .rodata
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250929-jag-nmiwd_const-v1-1-92200d503b1f@kernel.org>
X-B4-Tracking: v=1; b=H4sIANqr2mgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyNL3azEdN283MzylPjk/LziEt0UcxMj48QkI1MTSzMloK6CotS0zAq
 widGxtbUAqzFcmmEAAAA=
X-Change-ID: 20250929-jag-nmiwd_const-d7423ab25496
To: Petr Mladek <pmladek@suse.com>, Daniel Xu <dlxu@meta.com>
Cc: linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2198;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=5ZiYViMmHyYTGbotSTQoJNHs5BRuX6SdoxN8p8nXJh0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjaq+COM2Svc8jNNFjm5q85lI9TkhtAfjlfy
 8z8sh5u2LRDLokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo2qvgAAoJELqXzVK3
 lkFPzlAL/3fhRZbC1qSPUyUYd6UjCH1DU3lx6hp+FzCodX/p2mgTY/luqaOVtuTMqewvQVAJ4dV
 RbrlwckF82kME1qIKhRyrdZrlIGxNwoe6wMf7Ji58iV0YKQXLySYW/Q44x5byReySl6ONNJ1fvR
 3KFPTGU3FQKR8tYayZjjVQyUa/U0B2NyvoPfPJJoqnTo0fXcZTbWdldXDrloJ/HBaip9agWMrgk
 slAItrraZlt3emPeLB0BslyyaClokokTiB4hwq9iaJhLBTtPF/r0E/UQ3nu21DSIRe9z9+HCuuP
 3gPD5+XdsN6Xk0ZKJYivG+5NlHFSa4utglLilzdyiUGvRy9NQAprx/I/8X+Po0cZgfUxEvGaHmA
 0oW/14sZzvzR0WBb6qAIacHvUF2cKkhXohfFxYPrsiK4zH7oc10HM5pctdsLOogMS47+raE+NqC
 ktzJ4mcOjjaTZtKO+Q3mjb3eRdqXoAXabOVJIRQlugNiUI8PpGIWrfZTKqxiV7yLcXYqqu+MIt7
 eU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move nmi_watchdog into the watchdog_sysctls array to prevent it from
unnecessary modification. This move effectively moves it inside the
.rodata section.

Initially moved out into its own non-const array in commit 9ec272c586b0
("watchdog/hardlockup: keep kernel.nmi_watchdog sysctl as 0444 if probe
fails"), which made it writable only when watchdog_hardlockup_available
was true. Moving it back to watchdog_sysctl keeps this behavior as
writing to nmi_watchdog still fails when watchdog_hardlockup_available
is false.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
This patch is a followup on the discussion/question I had in [1]. I
would prefer this to be const as it locks things in .rodata and prevents
inadvertent modifications [2].

[1] https://lore.kernel.org/all/588ec9ab-b38a-40b3-8db5-575a09e9a126@meta.com/
[2] https://lore.kernel.org/all/20250109-jag-ctl_table_const-v1-1-622aea7230cf@kernel.org/
---
 kernel/watchdog.c | 9 +--------
 1 file changed, 1 insertion(+), 8 deletions(-)

diff --git a/kernel/watchdog.c b/kernel/watchdog.c
index 80b56c002c7f123c49f65465fe7af9c74de4f46a..1e4e3eccb065a5ce95486f24fa07387e8218cd62 100644
--- a/kernel/watchdog.c
+++ b/kernel/watchdog.c
@@ -1213,14 +1213,11 @@ static const struct ctl_table watchdog_sysctls[] = {
 	},
 #endif /* CONFIG_SMP */
 #endif
-};
-
-static struct ctl_table watchdog_hardlockup_sysctl[] = {
 	{
 		.procname       = "nmi_watchdog",
 		.data		= &watchdog_hardlockup_user_enabled,
 		.maxlen		= sizeof(int),
-		.mode		= 0444,
+		.mode		= 0644,
 		.proc_handler   = proc_nmi_watchdog,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -1230,10 +1227,6 @@ static struct ctl_table watchdog_hardlockup_sysctl[] = {
 static void __init watchdog_sysctl_init(void)
 {
 	register_sysctl_init("kernel", watchdog_sysctls);
-
-	if (watchdog_hardlockup_available)
-		watchdog_hardlockup_sysctl[0].mode = 0644;
-	register_sysctl_init("kernel", watchdog_hardlockup_sysctl);
 }
 
 #else

---
base-commit: e5f0a698b34ed76002dc5cff3804a61c80233a7a
change-id: 20250929-jag-nmiwd_const-d7423ab25496

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

