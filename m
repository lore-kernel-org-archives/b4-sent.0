From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH 0/2] clk: qcom: sdm660: keep USB across suspend, give
 mdss_axi_clk its parent
Date: Mon, 28 Sep 2026 14:41:42 -0300
Message-Id: <20260928-sdm660-clk-fixes-v1-0-5d5bb84e3258@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyML3eKUXDMzA93knGzdtMyK1GJdSwvTFHPjNMsUAwtjJaC2gqJUsAR
 QV3QshF9cmpSVmlwCMkepthYAAAW52nQAAAA=
X-Change-ID: 20260928-sdm660-clk-fixes-985d73f9d083
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@somainline.org>, 
 Martin Botka <martin.botka@somainline.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790617365; l=1346;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=UgHcAAifO+PHlPWDmTFaARyXgKchbIalMKJEuI385eU=;
 b=oSW+5Bw6ht+5p4LJMdS/Dwc0QdWnJhTto3uB59qRWjjNWyLbnT6t1rBf8u8VA9XhT0z/1TAso
 /wUQA6IgrC7AmBVuUO9SH4evIaq+RPSKJxhgh5cTIlftM73kNKUF3An
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two independent fixes to the SDM660 clock controllers, found while
bringing up the Motorola Moto X4 (payton, SDM630).

The first keeps the USB GDSC in retention across system suspend, as
msm8996, msm8998 and sm6375 already do. Switching it off loses the
DWC3 glue's QSCRATCH configuration, and USB does not come back after
resume.

The second sets num_parents on mdss_axi_clk. Without it the branch is
registered with no parent, reports 0 Hz, and enabling it takes no
reference on axi_clk_src.

Tested on a Motorola Moto X4 (XT1900-6) with the sdm660-mainline 7.2.3
tree, where its board file lives. Without the first patch the USB
gadget is gone after an RTC-woken suspend; with it, it re-enumerates
over repeated cycles. With the second, clk_summary shows mdss_axi_clk
at 384 MHz under axi_clk_src instead of 0 Hz with no parent. Both
apply unchanged to next-20260928.

---
Fabricio Akio (2):
      clk: qcom: gcc-sdm660: Keep the USB GDSC in retention
      clk: qcom: mmcc-sdm660: set num_parents on mdss_axi_clk

 drivers/clk/qcom/gcc-sdm660.c  | 3 ++-
 drivers/clk/qcom/mmcc-sdm660.c | 1 +
 2 files changed, 3 insertions(+), 1 deletion(-)
---
base-commit: 6375e61c01e93e35ee7acd336a689ac1fae4b509
change-id: 20260928-sdm660-clk-fixes-985d73f9d083

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

