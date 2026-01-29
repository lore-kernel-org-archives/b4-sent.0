From: Ben Zong-You Xie <ben717@andestech.com>
Date: Thu, 29 Jan 2026 14:43:34 +0800
Subject: [PATCH] drivers: pwm: remove redundant check in pwm_ops_check()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260129-fix-pwm-ops-check-v1-1-6f0b7952c875@andestech.com>
X-B4-Tracking: v=1; b=H4sIAJUBe2kC/yXM0QqCQBCF4VeRuW5gXWnFXiW6sPGkU6TLTmUgv
 rubXX5wzr+QISmMTsVCCR81ncaM8lCQDO3Yg7XLJu98cKVv+KZfjvOTp2gsA+TBAVUQuKarjy3
 lX0zIo715vvxt7+sd8vqFaF03ID1zUnUAAAA=
X-Change-ID: 20260129-fix-pwm-ops-check-6e36ce09d75a
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769669016; l=921;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=a9RiAo/8R5Tlj69Vgjm25sELpahOvVfSyEKanqMOV6w=;
 b=Nrmpy0YBi+qTZA1mdEGrL7qlV12ahfdGG6oB2rJsfhbhY+RsXosr35fGWTQ+l0Rvj4JIorvaq
 8X+fdBpMZ+uAxJorkkke1Cq+oZDPY755nr65xlhmsLXz9wfMI4X5oxz
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop the redundant check for the existence of 'ops->write_waveform'.

Fixes: 17e40c25158f ("pwm: New abstraction for PWM waveforms")
Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
 drivers/pwm/core.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/pwm/core.c b/drivers/pwm/core.c
index ec8731515333..450aedd32c81 100644
--- a/drivers/pwm/core.c
+++ b/drivers/pwm/core.c
@@ -1699,8 +1699,7 @@ static bool pwm_ops_check(const struct pwm_chip *chip)
 
 	if (ops->write_waveform) {
 		if (!ops->round_waveform_tohw ||
-		    !ops->round_waveform_fromhw ||
-		    !ops->write_waveform)
+		    !ops->round_waveform_fromhw)
 			return false;
 
 		if (PWM_WFHWSIZE < ops->sizeof_wfhw) {

---
base-commit: 63faf32666e03a78cc985bcbae196418cf7d7938
change-id: 20260129-fix-pwm-ops-check-6e36ce09d75a

Best regards,
--  
Ben Zong-You Xie <ben717@andestech.com>

