From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/2] clk: qcom: gcc-{sm8550/sm8650}: Fix UFS resume from
 suspend issue
Date: Thu, 07 Nov 2024 11:58:08 +0000
Message-Id: <20241107-ufs-clk-fix-v1-0-6032ff22a052@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFCrLGcC/x2MQQqAIBAAvyJ7bkHFEPtKdAhbaykslCIQ/550n
 IGZApkSU4ZBFEj0cOYzNlCdAL/NcSXkpTFoqY1S0uIdMvpjx8AvknFEWjrbOwOtuBI1/d/GqdY
 PcoxysV0AAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Amit Pundir <amit.pundir@linaro.org>, 
 Nitin Rawat <quic_nitirawa@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=806;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Gh/ompZkwURn0PwOkifty4Ajs5DMdgzLZxjoSuHPK3g=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnLKtReLRazqpEK4DZPuTzY71FdYMrbx2WEhOnt
 pZm60uhuSqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZyyrUQAKCRBVnxHm/pHO
 9VgjB/4iieean0IziLGHHrJI59WIFDmy9utZzqMMwJ049ru36KmxBmdBfCp/UH9YzV1W8wEZal3
 AdKLjERvX+l+N16/j05L32RWjxq3y9usqz12ulTYMA4k9qi07uZEq4CRaYBNz505MdzGdxosVJq
 LcZZfRQMYTylWvl9rwXw5FcyDcmQ5Y//uRQLutgxRznjTOMEwAybvCLjt/qSDs8zUrEZ9aC2Nc+
 P87+TBbDA4mw/Y/90cJpPBEXoVLa2MgjzhUboLaQaMMZzXA448r8Fp+DL60/m4/U1dKveuK1NUN
 8UTh6pljk9YPKANcqyUalQkye156zFnanrZkGNU5VCYEfm65
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the UFS resume from suspend issue by marking the UFS PHY GDSCs
as ALWAYS_ON. Starting from SM8550, UFS PHY GDSCs doesn't support retention
state. So we should keep them always on so that they don't loose the state
during suspend.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (2):
      clk: qcom: gcc-sm8550: Keep UFS PHY GDSCs ALWAYS_ON
      clk: qcom: gcc-sm8650: Keep UFS PHY GDSCs ALWAYS_ON

 drivers/clk/qcom/gcc-sm8550.c | 4 ++--
 drivers/clk/qcom/gcc-sm8650.c | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)
---
base-commit: 9852d85ec9d492ebef56dc5f229416c925758edc
change-id: 20241107-ufs-clk-fix-e49ee2097594

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

