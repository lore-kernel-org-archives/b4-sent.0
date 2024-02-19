From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/2] watchdog: sp805: add reset control support
Date: Tue, 20 Feb 2024 02:14:24 +0800
Message-Id: <20240220-hisi-wdt-v2-0-63edc4965b4c@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAICa02UC/22MSw7CIBQAr9K8tRhA20pX3sN0wU9L1D4DiJqGu
 /vs2uVMJrNA8jH4BEOzQPQlpIAzgdw0YCc9XzwLjhgkl3suRc8mStjLZbYzrVS90F2rBFD+iP4
 c3uvqNBJTmDF+1nMRP/tnUgTjzDqjnLPaqO5wxGe+IV63Fu8w1lq/k5lSPqIAAAA=
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Viresh Kumar <vireshk@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708366465; l=825;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=3p90HdXjRYqaF/dwaJSI6JIUSflQuajrLtO/CzXAHow=;
 b=NY9tsSJ4I1KQNgp+4GHYAc0+8hARqMhSN/cqcCnZLV6CXiW8r+zNewLjP58YJ0cUqEk40u7cD
 Con8Y6VpnijAo3L23KyUzMSeGccNOoyrvkinvy/mlYNpfGz63CNGWh9
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Deassert the reset if it's available.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- commit log: dt-binding->dt-bindings (Krzysztof Kozlowski)
- binding: remove "|", join two lines. (Krzysztof Kozlowski)
- Link to v1: https://lore.kernel.org/r/20240217-hisi-wdt-v1-0-cdb9ddcab968@outlook.com

---
Yang Xiwen (2):
      watchdog: sp805_wdt: deassert the reset if available
      dt-bindings: watchdog: arm,sp805: document the reset signal

 Documentation/devicetree/bindings/watchdog/arm,sp805.yaml | 5 +++++
 drivers/watchdog/sp805_wdt.c                              | 9 +++++++++
 2 files changed, 14 insertions(+)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240217-hisi-wdt-3b52971a6591

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

