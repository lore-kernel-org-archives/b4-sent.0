From: Igor Velkov <iav@iav.lv>
Subject: [PATCH 0/2] Label the fans on Kobol Helios64
Date: Sun, 18 Oct 2026 07:54:58 +0300
Message-Id: <20261018-helios64-fan-label-v1-0-69a3f96d4efa@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACJR1GoC/x3MQQqEMAxG4atI1gaMDipeRVykM79joFRpQYTi3
 S0uv8V7mRKiIdFUZYo4LdkeCqSu6Ltp+IPtV0xt0/bSyMgbvO2p//Cqgb06eFYZOsUgDg5UwiN
 iteudzst9P0FKSfJkAAAA
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1298; i=iav@iav.lv;
 h=from:subject:message-id; bh=fUdq2VvosvV5UWVKEKg821xAaTCVqPc2wV9SA9hzTFA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlXAlVnOwqGVKsLxp8pFLmVty+gpnDn3QfGWpO672yNT
 Nv5MPtuRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZjIcSeG/znP3I4tdzJ2dc71
 3fzX/M6ErX+XmzBnMzFNmvo3fOa0nU2MDM8+G82JLt9QcuiksMlzXQGPoD3Kc49b287pUZ18Wmx
 uNCcA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Helios64 has two identical PWM fans, and userspace can tell them apart
only by their platform device names. Patch 1 makes pwm-fan.yaml
reference fan-common.yaml, as Rob suggested, which also allows label;
the hwmon core already exposes it as the label attribute. Patch 2 names
the fans after their headers, P6 and P7.

To: Guenter Roeck <linux@roeck-us.net>
To: Jean Delvare <jdelvare@suse.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Heiko Stuebner <heiko@sntech.de>
Cc: linux-hwmon@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-rockchip@lists.infradead.org
Cc: linux-kernel@vger.kernel.org

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Igor Velkov (2):
      dt-bindings: hwmon: pwm-fan: Reference the common fan schema
      arm64: dts: rockchip: Label the fans on Kobol Helios64

 .../devicetree/bindings/hwmon/pwm-fan.yaml         | 22 +++++-----------------
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts    |  4 ++--
 2 files changed, 7 insertions(+), 19 deletions(-)
---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261018-helios64-fan-label-a173ae71bebe

Best regards,
-- 
Igor Velkov <iav@iav.lv>

