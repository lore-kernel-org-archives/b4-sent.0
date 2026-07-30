From: =?utf-8?q?Dawid_Wro=CC=81bel?= <me@dawidwrobel.com>
Date: Thu, 30 Jul 2026 15:44:07 +0200
Subject: [PATCH] arm64: dts: qcom: sm8250-xiaomi-elish: correct the board
 ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260730-elish-board-id-v1-1-92f99e9722ec@dawidwrobel.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7TjCltL4SHUy3XAgNhQjEvycdh
 2GmQMZEmGHpCiR8KFMMDYa+A+tNOJGRawyCi4kryRlelD3bo0muKaatdbPRo5JaQIvuhAe9/3D
 dav0AcqmXi2AAAAA=
X-Change-ID: 20260730-elish-board-id-8ccd9a857382
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jianhua Lu <lujianhua000@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Dawid_Wro=CC=81bel?= <me@dawidwrobel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1968; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=g2fcCipVqt2i1yfS91bVrhhCHQ1qcOIxuxiWk6CgcA8=;
 b=kA0DAAoWynV8R6nV7u0ByyZiAGprVS7IpwJaoOcWCNIk/6xxU2PlpnqNRIfQW/7aagx5XWc5T
 Yh1BAAWCgAdFiEELmZSvDpT6ffu6PtXynV8R6nV7u0FAmprVS4ACgkQynV8R6nV7u0SNwEAkN19
 VoNGLym2TUlAVfOUATPIQKKQt4u0HEVgo6pAwhYBAJ69dfHOjwk/NhcCL3SOv2gvvkxBkaTibZB
 3SQye/SkH
X-Developer-Key: i=me@dawidwrobel.com; a=openpgp;
 fpr=B64A778E0E64049A70C831C8B7B81FA12B282A92
X-Endpoint-Received: by B4 Relay for me@dawidwrobel.com/default with auth_id=901
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

elish declares the same qcom,msm-id and qcom,board-id pair as
sm8250-sony-xperia-edo.dtsi, so a bootloader choosing between appended
device trees cannot tell the two boards apart.

0x10008 is Sony's value. The downstream device tree for this board,
elish-sm8250-overlay.dts, uses qcom,board-id = <47 0>, i.e. platform
type 0x2f.

Fixes: a41b617530bf ("arm64: dts: qcom: sm8250: Add device tree for Xiaomi Mi Pad 5 Pro")
Signed-off-by: Dawid Wróbel <me@dawidwrobel.com>
---
Not tested on elish hardware: the corrected value comes from the
downstream device tree:
https://github.com/LineageOS/android_kernel_xiaomi_sm8250/blob/a04dba03999b36cc8f472c014063395b41fb1022/arch/arm64/boot/dts/vendor/qcom/elish-sm8250-overlay.dts#L14

That import commit (bf5acbcaca99) credits Xiaomi's munch-s-oss and
dagu-s-oss releases; Xiaomi's published kernel repo doesn't contain
the device trees, so LineageOS seems to be the only public source.

No user-visible impact: nothing in the kernel reads qcom,board-id, and it
is only consulted when a bootloader selects between several appended
device trees. Not needed for stable.
---
 arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
index 19aff83ecf7b..945127dacc82 100644
--- a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
@@ -29,7 +29,7 @@ / {
 
 	/* required for bootloader to select correct board */
 	qcom,msm-id = <QCOM_ID_SM8250 0x20001>; /* SM8250 v2.1 */
-	qcom,board-id = <0x10008 0>;
+	qcom,board-id = <0x2f 0>;
 
 	aliases {
 		serial0 = &uart6;

---
base-commit: 7f102800164990609e2b272396d45b197a55bd04
change-id: 20260730-elish-board-id-8ccd9a857382

Best regards,
-- 
Dawid Wróbel <me@dawidwrobel.com>

