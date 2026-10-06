From: Matt Layher <mdlayher@gmail.com>
Subject: [PATCH v3] hwmon: (asus-ec-sensors) add CPU_Opt fan for ROG STRIX
 X570-E GAMING
Date: Tue, 06 Oct 2026 10:35:36 -0400
Message-Id: <20261006-asus-ec-x570e-cpu-opt-v3-0-62672edc18b3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNyw6CMBBFf4V07Zh2Cm1w5X8YF7UMUCOPtEAwh
 H+X4oaNcXmSe89ZWCDvKLBLsjBPkwuuazeQp4TZ2rQVgSs2ZshRCc5TMGEMQBbmTHMC24/Q9QM
 olAqFKbnOOdu+vafSzbv3dv9yGB9PskOUxUXtwtD59x6eRNz9a0wCBBQ5GamFlbzIrlVj3Otsu
 4bFxoRHi/plwc2i06JEaRFLnh4t67p+AFZl/QsSAQAA
X-Change-ID: 20261004-asus-ec-x570e-cpu-opt-623621af0790
To: Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Matt Layher <mdlayher@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791297407; l=1127;
 i=mdlayher@gmail.com; s=linuxdev; h=from:subject:message-id;
 bh=Du715d/GXvp0weHXce0cb9IcYUZ3N2wWS85/a0Xjye0=;
 b=2onDSZxHI3ZVFEXxDP3FKcJi9OA2AamFktHt7ILCv/AK84Ex0blmA3hte5x8cmrj4v0T6JvL5
 N7iei+Gj9MFBYTj97ZU6hNiJ0huRbTlrdERJr4UwqujMr+J5MU6XyId
X-Developer-Key: i=mdlayher@gmail.com; a=ed25519;
 pk=jO44g3WNw2T0EoKPeB+RUgDmyrZpA5Pmr830ITlwhaA=
X-Endpoint-Received: by B4 Relay for mdlayher@gmail.com/linuxdev with auth_id=1109
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Testing:
- Runtime: the same one-line change applied to the driver in v6.18.54,
  loaded on the board in place of the stock module; CPU_Opt read
  1454-1463 RPM and the chipset fan 0.
- Build: hwmon-next with W=1 and sparse (C=1), no warnings;
  checkpatch --strict reports no errors, warnings or checks.

Signed-off-by: Matt Layher <mdlayher@gmail.com>
---
Changes in v3:
- Drop the LLM usage note in favor of the Assisted-by tag (Eugene).
- Move the testing notes to a cover letter (Eugene).
- Link to v2: https://patch.msgid.link/20261006-asus-ec-x570e-cpu-opt-v2-1-74df23c22f04@gmail.com

Changes in v2:
- Shorten the commit message (Eugene).
- Link to v1: https://patch.msgid.link/20261004-asus-ec-x570e-cpu-opt-v1-1-d9ea371c30d5@gmail.com

---
Matt Layher (1):
      hwmon: (asus-ec-sensors) add CPU_Opt fan for ROG STRIX X570-E GAMING

 drivers/hwmon/asus-ec-sensors.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
---
base-commit: 4781ca52761e666cf18b591e6bb0478396c90320
change-id: 20261004-asus-ec-x570e-cpu-opt-623621af0790

Best regards,
--  
Matt Layher <mdlayher@gmail.com>

