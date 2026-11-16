From: David Heidelberg <david@ixit.cz>
Date: Mon, 16 Nov 2026 16:50:45 +0100
Subject: [PATCH v3 3/3] arm64: dts: qcom: sdm845-google: Require modem
 socinfo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-modemsmem-v3-3-24ebc7ed6eb9@ixit.cz>
References: <20261116-modemsmem-v3-0-24ebc7ed6eb9@ixit.cz>
In-Reply-To: <20261116-modemsmem-v3-0-24ebc7ed6eb9@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Miro Mraz <mraz.miro@seznam.cz>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-remoteproc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1063; i=david@ixit.cz;
 h=from:subject:message-id; bh=b1c7/PH/ZBn7CdtqlJWGuvtm6FqXDNuZ6icQBu1gPcY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq+yZfCBjZfqAB9dl+hwLxqMcVD+vRV83mg27jl
 mjt0BEn8kKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavsmXwAKCRBgAj/E00kg
 cpW7D/0ad5tAGVKYbk22HnkEzkUniurD9zTrHxnP69SKU6x4Vk3wz6hWCgU2RkTXbnS3noCyr+P
 xXYgsUeSqtbijHuOeL1RRgnm4KVF2YQoBUTC4ckQjawG4amRkXVdrCCKnS0boFfYacgvo/YDK3i
 nEGJr3UjkJTtSJ1BXFKBBk8NkRvD4uL9n0QlwENblcczRk1UfdUoQWQvyKRFa7Bmic139oHN7BY
 CSyBlFOImkl4BHZfZAgDAR6Sr89z4hODyLsLGezuku+LZHeBEIlV/UlTp7k1rB0214w0z399Rlu
 ogePFbq4kOi1WdobGimlDW2pCh9RWzbSTRwHY95ew8yy7FM3odS3PvqtrTMnSyt2miboLtxNTdQ
 BA2up2/kImr16CTATZ06fKn+IuaUgKU4OGYVrvudnvHqaXLJOTX4SImKsoUBxdHkA+SSGRBq0Uo
 AQObPCpxQ1mnRjJ9aub3RVFJvN8alCSVQmugkknCg+hpQgaM73QgrCnNzyEOAgirNrpuZ0zPzwC
 jVWt/IjpLyWGBld6doRb1ELF80zxfvMLmgeFPb98sMrlrvWixFvULVkHzsA3pT4t/uNpFmJZjT4
 SzMJ72yNm1L9rgKVSBgBczue034etP1O/Pf+8e9KolQX6Tim9mhNMI2iIrrk1SSLtsXP261S78K
 igwr5kv6j4Nf9hA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The modem firmware on the Google Pixel 3 and Pixel 3 XL reads the SoC
platform information from the first vendor-reserved SMEM item before
booting. Add the google,require-socinfo property to the MSS remoteproc
node so the MSS driver publishes it.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 3c9656b88b696..0a18d9a124566 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -426,16 +426,18 @@ &ipa {
 &mdss {
 	status = "okay";
 };
 
 &mss_pil {
 	firmware-name = "qcom/sdm845/Google/blueline/mba.mbn",
 			"qcom/sdm845/Google/blueline/modem.mbn";
 
+	google,require-socinfo;
+
 	status = "okay";
 };
 
 &pm8998_gpios {
 	volume_up_gpio: vol-up-active-state {
 		pins = "gpio6";
 		function = "normal";
 		input-enable;

-- 
2.55.0

