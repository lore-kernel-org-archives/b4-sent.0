From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Tue, 02 Jun 2026 16:19:20 +0200
Subject: [PATCH v3] thermal: amlogic: add missing dependency on MESON_SM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-fix-missing-meson_sm-symbol-v3-1-6f7f69cd7d6c@aliel.fr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6DIBCF4asY1qUBbEG66j2aplEBnUSwYRpSY
 7x70XThyuX/MvlmJmgjWCS3YibRJkAYQ47yVJC2r0NnKZjcRDAh2VVo6uBLPSBC6Ki3OIYXeoq
 Tb8aBKqWkYUYbJRnJwjvafL7pj2fuHvAzxml7lvi6/t2SHbqJU05L10glGl1pc7nXA9jh7CJZ2
 ST2FD+mRKa4sa5qy5ZL7XbUsiw/nGGjcxABAAA=
X-Change-ID: 20260529-fix-missing-meson_sm-symbol-7776d0d9d760
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Lukasz Luba <lukasz.luba@arm.com>
Cc: Guillaume La Roque <glaroque@baylibre.com>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Mark Brown <broonie@kernel.org>, kernel test robot <lkp@intel.com>, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1769;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=Ugj/bC+OamV3jyF8WcVc9eTJZxuCATwhl48WC6wVttE=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ5bc88YZf93YKuZbvUs0urjHhjFyltZXW8tXjJrH173aH
 8wqovmqo5SFQYyLQVZMkaV/ruWJd5ePnvm6Rz0FZg4rE8gQBi5OAZhIhRHDP7upL/kyYjSthN9t
 V4/k/yC493zz9qe5b7r2HD1fMOP35k0Mf7gjVVZsajNQ618UsM587vaA6X9u7Qxb6mX9+nMz04t
 9v/gA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The amlogic thermal driver calls meson_sm_get() and
meson_sm_get_thermal_calib() which are exported by the meson_sm
driver. Without CONFIG_MESON_SM enabled, the build fails with
undefined references to these symbols.

Add a proper Kconfig dependency on MESON_SM instead of relying on
stub functions, which makes the dependency explicit and prevents
invalid configurations.

Closes: https://lore.kernel.org/oe-kbuild-all/202605291530.en7aGn7w-lkp@intel.com/
Reported-by: Mark Brown <broonie@kernel.org>
Reported-by: kernel test robot <lkp@intel.com>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Changes in v3:
- Add a dependency on MESON_SM instead of stub functions.
- Link to v2: https://lore.kernel.org/r/20260531-fix-missing-meson_sm-symbol-v2-1-1def8c3c169f@aliel.fr

Changes in v2:
- Replace #ifdef CONFIG_MESON_SM by #if IS_ENABLED(CONFIG_MESON_SM)
  to cover builtin and module in config.
- Add missing trailers for kernel test robot.
- Link to v1: https://lore.kernel.org/r/20260530-fix-missing-meson_sm-symbol-v1-1-3fb672b989d4@aliel.fr
---
 drivers/thermal/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/thermal/Kconfig b/drivers/thermal/Kconfig
index 1c4a5cd5a23ee..810eeccedfbab 100644
--- a/drivers/thermal/Kconfig
+++ b/drivers/thermal/Kconfig
@@ -436,6 +436,7 @@ config AMLOGIC_THERMAL
 	tristate "Amlogic Thermal Support"
 	default ARCH_MESON
 	depends on OF && ARCH_MESON
+	depends on MESON_SM
 	help
 	  If you say yes here you get support for Amlogic Thermal
 	  for G12 SoC Family.

---
base-commit: 3929405c64376a8a54c794e8a4485023b108a97e
change-id: 20260529-fix-missing-meson_sm-symbol-7776d0d9d760

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

