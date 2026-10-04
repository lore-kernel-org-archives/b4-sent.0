From: Matt Layher <mdlayher@gmail.com>
Date: Sun, 04 Oct 2026 10:26:27 -0400
Subject: [PATCH] hwmon: (asus-ec-sensors) add CPU_Opt fan for ROG STRIX
 X570-E GAMING
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-asus-ec-x570e-cpu-opt-v1-1-d9ea371c30d5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTvJtEKJXsW4qHWAYQFNpzUkh
 LtTdfkW/++gnIQV7s0OiT+isi4V5tJAmPwyMsq7GixZZ4ha9FoUOeDW9cQYYsE1ZnT26qzxA/U
 3gtrGxINsv+/j+beW18whf2dwHCcRgOQSeQAAAA==
X-Change-ID: 20261004-asus-ec-x570e-cpu-opt-623621af0790
To: Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Matt Layher <mdlayher@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791124002; l=2211;
 i=mdlayher@gmail.com; s=linuxdev; h=from:subject:message-id;
 bh=HEHb7pz+5CIVTAUXjsxnncxE0oQGAoREpSaAebUx9AQ=;
 b=lH+GY7hQhCIRrlVSwJEabDbMMuuSttNbGlGKto0goC43sa7ced/zA6BldftpntEozBMDear3u
 374btCATaKDBmZqbkFcVxUwTjxw+zVZyahe44B4ZuLzAzq5fosBTLGC
X-Developer-Key: i=mdlayher@gmail.com; a=ed25519;
 pk=jO44g3WNw2T0EoKPeB+RUgDmyrZpA5Pmr830ITlwhaA=
X-Endpoint-Received: by B4 Relay for mdlayher@gmail.com/linuxdev with auth_id=1109
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the CPU_Opt fan sensor for ROG STRIX X570-E GAMING.

The board has a CPU_OPT fan header, and its UEFI hardware monitor shows a
fan connected to it spinning at about 2000 RPM, but the driver does not
expose the sensor and the board's NCT6798D does not report it either.

Reading the EC directly through ec_sys on this board (BIOS 4408), the
CPU_Opt register used by the rest of the AMD 500 series family (bank 0,
0xb0) returns 0x0580, 1408 RPM under the operating system's fan curve,
while the chipset fan register at 0xb4 returns 0, matching what the
driver already reports for that fan.

Assisted-by: LLM sparse
Signed-off-by: Matt Layher <mdlayher@gmail.com>
---
An LLM coding assistant did most of the work on this patch: it found the
missing sensor while auditing this machine's monitoring, compared the
driver's board table with the BIOS hardware monitor, worked out which EC
register to read, and drafted the change and this changelog. I
reviewed both, and every test below ran on my own machines.

Testing:
- Runtime: the same one-line change applied to the driver in v6.18.54,
  loaded on the board in place of the stock module; CPU_Opt read
  1454-1463 RPM and the chipset fan 0.
- Build: hwmon-next with W=1 and sparse (C=1), no warnings;
  checkpatch --strict reports no errors, warnings or checks.
---
 drivers/hwmon/asus-ec-sensors.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwmon/asus-ec-sensors.c b/drivers/hwmon/asus-ec-sensors.c
index 19f423e45ce5..8261ddd00653 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -721,7 +721,7 @@ static const struct ec_board_info board_info_strix_x470_i_gaming = {
 
 static const struct ec_board_info board_info_strix_x570_e_gaming = {
 	.sensors = SENSOR_SET_TEMP_CHIPSET_CPU_MB |
-		SENSOR_TEMP_T_SENSOR |
+		SENSOR_TEMP_T_SENSOR | SENSOR_FAN_CPU_OPT |
 		SENSOR_FAN_CHIPSET | SENSOR_CURR_CPU |
 		SENSOR_IN_CPU_CORE,
 	.mutex_path = ASUS_HW_ACCESS_MUTEX_ASMX,

---
base-commit: 4781ca52761e666cf18b591e6bb0478396c90320
change-id: 20261004-asus-ec-x570e-cpu-opt-623621af0790

Best regards,
--  
Matt Layher <mdlayher@gmail.com>

