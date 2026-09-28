From: Fabricio Akio <fabricioakio@gmail.com>
Date: Mon, 28 Sep 2026 14:41:43 -0300
Subject: [PATCH 1/2] clk: qcom: gcc-sdm660: Keep the USB GDSC in retention
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-sdm660-clk-fixes-v1-1-5d5bb84e3258@gmail.com>
References: <20260928-sdm660-clk-fixes-v1-0-5d5bb84e3258@gmail.com>
In-Reply-To: <20260928-sdm660-clk-fixes-v1-0-5d5bb84e3258@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@somainline.org>, 
 Martin Botka <martin.botka@somainline.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790617365; l=1139;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=HV7dwPBmvRBQNBJ98Zjm+LuO+57weRugd9Y05jqgzHA=;
 b=P8MWtpsxM/ZKUrdFimVn6YPgSU5QAohnQtv+C4BmsXTNhy4qsUh+SaUoIkTByKDrv9MXnvjSJ
 SJon2rK4PRjCMp2yZ9S7fck4/pix0+MQL3Nqf0JjavAXLU/hkRiL40D
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DWC3 glue writes its QSCRATCH configuration only at probe. When
system suspend switches usb_30_gdsc off, that configuration is lost
and on resume the core fails to enable endpoint 0. Keep the GDSC in
retention, as is already done on:

  commit 78a2f2a04fb5 ("clk: qcom: gcc-msm8996: Update the .pwrsts for
  usb gdsc")
  commit 83fddbcc8337 ("clk: qcom: gcc-msm8998: Update the .pwrsts for
  usb gdsc")

This change should be reverted when a proper suspend sequence is
implemented in the USB drivers.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 drivers/clk/qcom/gcc-sdm660.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/qcom/gcc-sdm660.c b/drivers/clk/qcom/gcc-sdm660.c
index 20253a06a583..5d00f1fd4d53 100644
--- a/drivers/clk/qcom/gcc-sdm660.c
+++ b/drivers/clk/qcom/gcc-sdm660.c
@@ -2302,7 +2302,8 @@ static struct gdsc usb_30_gdsc = {
 	.pd = {
 		.name = "usb_30_gdsc",
 	},
-	.pwrsts = PWRSTS_OFF_ON,
+	/* TODO: Change to OFF_ON when USB drivers get proper suspend support */
+	.pwrsts = PWRSTS_RET_ON,
 	.flags = VOTABLE,
 };
 

-- 
2.55.0

