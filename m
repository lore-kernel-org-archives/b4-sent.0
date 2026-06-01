From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Date: Mon, 01 Jun 2026 18:54:00 +0200
Subject: [PATCH v3 1/3] arm64: dts: qcom: sdm670: add default uart pinctrl
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-1-6fdcd669364e@postmarketos.org>
References: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-0-6fdcd669364e@postmarketos.org>
In-Reply-To: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-0-6fdcd669364e@postmarketos.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=4680;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=MsvdWsmedbXe2xM8qbb5uDnLO53eFeUuF5Xokz2VAkA=;
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBqHbk0YjoQjyloymB/7fvnJy2jVIYCAJCbI70oi
 MK5KEPlN+uJAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCah25NAAKCRB6NCVl/2Nf
 eUOUEACowkYCM3+NfDA2qf4y5iiRoa2EFQVSsyqEfMHw0G5gB6CoqvpOZ4RTyQxizcoQ5BszWca
 Yd2WnJ1nF08mFd3FeLl8fuBVfac/+O0lmbWNw3KsHhflzRhK8E4HxUe0vq60xuYDE/uTjIcOIFU
 wqwyqKlhyRNrAT2XQsOq0gt6Ut6unbODFZHqBAnducdnroVLzVku97FtOKKqEMvFdqedxKc3LMZ
 XVmOcF5gAefJd6aVlHsLWtfrvOVGRF2x50vzSJC/RDQjLxcriaNr6va5KtdrmgAazv41pDYd0rW
 rSrbJoS7SUmJRxzAP5bR6HWbQUQXmEYC3mT8Can1E+kFbTEmqGH6evQPc2YBD39rermS13uRQUG
 8ASw4KVQIQUhi93m5SpcwgRmL075enTcuNHNtiQLT0lca1RCT/5NVlmOLkh3zSCBxVn2wtn3ehR
 3+yiTg/nj2lD+rMkG+keK7EFbYVIPHOBOnqcX/agcTANG2dQXWgXPP3jTtRmAttAC58t3i8w2oF
 0vXbzohx/34fvPgnQwcvh3S1QcfODtjNjE61iAgXSi1ypYQwk+xZJEPECi03xMghBn5RC64C5Nj
 xzkLD/s8KoZ/lFkyhxcnbJPIfjpYMToz6hXfJIrCwy+56RDlDF3ECMg0N2Xp7K1RkQTK3TOAgXQ
 ItYqezi2KoXA2Jg==
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a pre-requisite to enable UART in sargo and bonito. Values for
the pins have been taken from sdm845, and cross-checking dowstream,
where available.

Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
---
 arch/arm64/boot/dts/qcom/sdm670.dtsi | 192 +++++++++++++++++++++++++++++++++++
 1 file changed, 192 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670.dtsi b/arch/arm64/boot/dts/qcom/sdm670.dtsi
index 30844b150c80..1c6c18a913a0 100644
--- a/arch/arm64/boot/dts/qcom/sdm670.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670.dtsi
@@ -1343,6 +1343,198 @@ qup_i2c15_default: qup-i2c15-default-state {
 				function = "qup15";
 			};
 
+			qup_uart0_default: qup-uart0-default-state {
+				qup_uart0_tx: tx-pins {
+					pins = "gpio2";
+					function = "qup0";
+				};
+
+				qup_uart0_rx: rx-pins {
+					pins = "gpio3";
+					function = "qup0";
+				};
+			};
+
+			qup_uart1_default: qup-uart1-default-state {
+				qup_uart1_tx: tx-pins {
+					pins = "gpio19";
+					function = "qup1";
+				};
+
+				qup_uart1_rx: rx-pins {
+					pins = "gpio20";
+					function = "qup1";
+				};
+			};
+
+			qup_uart2_default: qup-uart2-default-state {
+				qup_uart2_tx: tx-pins {
+					pins = "gpio29";
+					function = "qup2";
+				};
+
+				qup_uart2_rx: rx-pins {
+					pins = "gpio30";
+					function = "qup2";
+				};
+			};
+
+			qup_uart3_default: qup-uart3-default-state {
+				qup_uart3_tx: tx-pins {
+					pins = "gpio43";
+					function = "qup3";
+				};
+
+				qup_uart3_rx: rx-pins {
+					pins = "gpio44";
+					function = "qup3";
+				};
+			};
+
+			qup_uart4_default: qup-uart4-default-state {
+				qup_uart4_tx: tx-pins {
+					pins = "gpio91";
+					function = "qup4";
+				};
+
+				qup_uart4_rx: rx-pins {
+					pins = "gpio92";
+					function = "qup4";
+				};
+			};
+
+			qup_uart5_default: qup-uart5-default-state {
+				qup_uart5_tx: tx-pins {
+					pins = "gpio87";
+					function = "qup5";
+				};
+
+				qup_uart5_rx: rx-pins {
+					pins = "gpio88";
+					function = "qup5";
+				};
+			};
+
+			qup_uart6_default: qup-uart6-default-state {
+				qup_uart6_tx: tx-pins {
+					pins = "gpio47";
+					function = "qup6";
+				};
+
+				qup_uart6_rx: rx-pins {
+					pins = "gpio48";
+					function = "qup6";
+				};
+			};
+
+			qup_uart7_default: qup-uart7-default-state {
+				qup_uart7_tx: tx-pins {
+					pins = "gpio95";
+					function = "qup7";
+				};
+
+				qup_uart7_rx: rx-pins {
+					pins = "gpio96";
+					function = "qup7";
+				};
+			};
+
+			qup_uart8_default: qup-uart8-default-state {
+				qup_uart8_tx: tx-pins {
+					pins = "gpio67";
+					function = "qup8";
+				};
+
+				qup_uart8_rx: rx-pins {
+					pins = "gpio68";
+					function = "qup8";
+				};
+			};
+
+			qup_uart9_default: qup-uart9-default-state {
+				qup_uart9_tx: tx-pins {
+					pins = "gpio4";
+					function = "qup9";
+				};
+
+				qup_uart9_rx: rx-pins {
+					pins = "gpio5";
+					function = "qup9";
+				};
+			};
+
+			qup_uart10_default: qup-uart10-default-state {
+				qup_uart10_tx: tx-pins {
+					pins = "gpio53";
+					function = "qup10";
+				};
+
+				qup_uart10_rx: rx-pins {
+					pins = "gpio54";
+					function = "qup10";
+				};
+			};
+
+			qup_uart11_default: qup-uart11-default-state {
+				qup_uart11_tx: tx-pins {
+					pins = "gpio33";
+					function = "qup11";
+				};
+
+				qup_uart11_rx: rx-pins {
+					pins = "gpio34";
+					function = "qup11";
+				};
+			};
+
+			qup_uart12_default: qup-uart12-default-state {
+				qup_uart12_tx: tx-pins {
+					pins = "gpio51";
+					function = "qup12";
+				};
+
+				qup_uart12_rx: rx-pins {
+					pins = "gpio52";
+					function = "qup12";
+				};
+			};
+
+			qup_uart13_default: qup-uart13-default-state {
+				qup_uart13_tx: tx-pins {
+					pins = "gpio107";
+					function = "qup13";
+				};
+
+				qup_uart13_rx: rx-pins {
+					pins = "gpio108";
+					function = "qup13";
+				};
+			};
+
+			qup_uart14_default: qup-uart14-default-state {
+				qup_uart14_tx: tx-pins {
+					pins = "gpio31";
+					function = "qup14";
+				};
+
+				qup_uart14_rx: rx-pins {
+					pins = "gpio32";
+					function = "qup14";
+				};
+			};
+
+			qup_uart15_default: qup-uart15-default-state {
+				qup_uart15_tx: tx-pins {
+					pins = "gpio83";
+					function = "qup15";
+				};
+
+				qup_uart15_rx: rx-pins {
+					pins = "gpio84";
+					function = "qup15";
+				};
+			};
+
 			sdc1_state_on: sdc1-on-state {
 				clk-pins {
 					pins = "sdc1_clk";

-- 
2.54.0

