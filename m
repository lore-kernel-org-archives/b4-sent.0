From: Demeter Barna <me@fromdisposition.org>
Date: Fri, 27 Nov 2026 00:49:41 +0000
Subject: [PATCH] ASoC: qcom: sm8250: Add SM8350 sound card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-sm8350-sndcard-v1-1-50cbf3db3cb0@fromdisposition.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrA2YiUbxKtKFJpM6glEybRHEu
 5u2y7f4/wShxCTQFyck+rDwFjN0WYCbx/gkxT4bsEKrNbZK1s40lZLo3Zi8CmhsG+rGdh4hR3u
 iwMdvODz+lve0kHt9L3BdN+9fkRdyAAAA
X-Change-ID: 20261127-sm8350-sndcard-f2367f4568d2
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795740603; l=989;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=l+setiCU0+OrwLSvwV20cOvWy7hUFpop6hCa7bB/D/A=;
 b=AltFMW1XNwO+2+LBNBGdAAQvrRf7cfvJfXrIswCfQtiQgL/YZ0H6E9aJSwSTdZOoa+67UvSpq
 lqLnz9F5XjyA3JVjG//wp7kpKozWHAUoW946+XasIn5A3RPg5118co1
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Give the SM8350 sound card its own driver name, so UCM files can tell
it from SM8250.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
The qcom,sm8350-sndcard binding this matches is already in for-7.5
(a5b5d062b40c).
---
 sound/soc/qcom/sm8250.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/soc/qcom/sm8250.c b/sound/soc/qcom/sm8250.c
index d0015e5f5..ba0aaf428 100644
--- a/sound/soc/qcom/sm8250.c
+++ b/sound/soc/qcom/sm8250.c
@@ -231,6 +231,7 @@ static const struct of_device_id snd_sm8250_dt_match[] = {
 	{ .compatible = "qcom,qrb5165-rb5-sndcard", .data = "sm8250" },
 	{ .compatible = "qcom,sdm660-sndcard", .data = "sdm660" },
 	{ .compatible = "qcom,sm8250-sndcard", .data = "sm8250" },
+	{ .compatible = "qcom,sm8350-sndcard", .data = "sm8350" },
 	{}
 };
 

---
base-commit: 0fe506c81cc421509660163da72dac79adfb959a
change-id: 20261127-sm8350-sndcard-f2367f4568d2

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

