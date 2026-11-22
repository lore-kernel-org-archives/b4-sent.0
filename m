From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:12:54 +0000
Subject: [PATCH] ARM: dts: qcom: msm8974-hammerhead: Fix the IMU mount
 matrix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-hammerhead-imu-mount-matrix-v1-1-fa38561de9ca@enser.io>
X-B4-Tracking: v=1; b=H4sIANV5AmsC/yXNwQ6CMBAE0F8he3bVFhDjrxgP27LaNWkxWyAkh
 H+X6vFNJjMrZFbhDLdqBeVZsgxphzlU4AOlF6P0u8Ge7cUYa9E1GChG1sDUo8QJ4zClESONKgv
 Wjuhq665rW4J95KP8lOV3cH/8nSf3Zj+W1dJwlBmdUvKhRIWnuTs2qN7Ctn0B/W3cp6IAAAA=
X-Change-ID: 20261122-b4-hammerhead-imu-mount-matrix-3baa8237755a
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luca Weiss <luca@lucaweiss.eu>, EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324375; l=2485;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=a4Uo4loghWGDy2GdP4EuwRI5EW4ASIfAHB0njp2Ccko=;
 b=X1TaWiE38cpMtXb5uNSp4d/YoKHyq9QX4Bg98BlrKaSljImrXnX5hPRbOypyVdVOODDD9ruqZ
 Tu2mQBcmA2hDqfjWWWHr/XggwOEwiqHdl9nmvZfo9xjpYNuKrjG0PaS
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mount matrix added for the MPU6515 is the negative of the one the
vendor kernel uses. LG's hammerhead device tree maps the axes as

	axis_map_x = <1>; axis_map_y = <0>; axis_map_z = <2>;
	negate_x = <0>;   negate_y = <0>;   negate_z = <1>;

that is x = y_raw, y = x_raw, z = -z_raw, while the current matrix gives
x = -y_raw, y = -x_raw, z = z_raw. Every axis is inverted, so a phone
lying face up reads -1 g on z (face down), and held upright in portrait
it reads -1 g on y, which orientation daemons take as upside down: the
screen rotates to 180 degrees when the phone is held normally.

The current matrix also has determinant -1, a reflection, which no
physical mounting can produce. The vendor mapping is a proper rotation
and gives +1 g out of the screen when face up, as
Documentation/devicetree/bindings/iio/mount-matrix.txt expects.

Tested on a Nexus 5 running the postmarketOS 6.16 kernel with only this
matrix changed in its DTB. Held upright, sideways both ways and lying
face up, it read +9.7 m/s^2 on y, +9.7 and -9.7 on x, and +9.4 to +10.0
on z, and the orientation daemon turned the screen the right way up in
each case. With the old matrix, portrait was shown upside down. On
v7.4-rc2 the DTB builds with no new dtbs_check warnings.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: 73c9729f0fb5 ("ARM: dts: qcom: msm8974-hammerhead: add mount matrix for IMU")
Signed-off-by: EMCP333 <emcp@enser.io>
---
 arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts b/arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts
index e34d7b864e..9128c66125 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts
@@ -213,9 +213,9 @@ mpu6515@68 {
 		pinctrl-names = "default";
 		pinctrl-0 = <&mpu6515_pin>;
 
-		mount-matrix = "0", "-1", "0",
-				"-1", "0", "0",
-				"0", "0", "1";
+		mount-matrix = "0", "1", "0",
+				"1", "0", "0",
+				"0", "0", "-1";
 
 		i2c-gate {
 			#address-cells = <1>;

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-hammerhead-imu-mount-matrix-3baa8237755a

Best regards,
--  
EMCP333 <emcp@enser.io>

