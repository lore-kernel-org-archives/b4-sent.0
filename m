From: Colin Huang <u8813345@gmail.com>
Subject: [PATCH v4 0/3] add support for Delta E50SN12051
Date: Thu, 07 May 2026 13:12:25 +0800
Message-Id: <20260507-add-e50sn12051-v4-0-ff2b3768ac7e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADkf/GkC/33M0Q6CIBTG8VdxXEeDA4J11Xu0LhCOypbaoLGa8
 91Du3G5dfmds99/IhGDx0jOxUQCJh/9OOQhDwWxnRlapN7lTYCBYoIrapyjWLI4cGAlz7OCyji
 ltTYko0fAxr/W4PWWd+fjcwzvtZ/4cv2mJJx+U4lTRi1nHJWtWF3Xl7Y3/n60Y0+WVIINF2zHI
 XOnVYMSZAVmx8V/LjJvlJOYv2i13fJ5nj9NDVv/KgEAAA==
X-Change-ID: 20260316-add-e50sn12051-ad828ad6777a
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kevin Chang <kevin.chang2@amd.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778130752; l=2026;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=CZULrdKEKUjyo58BZeIybbnpWRynSP6n1PZzb6YPirY=;
 b=+BgMMz2iQjcARQdnDtHRIGv8FB+bP4ZOmwTQ7WxzCEHxW4kJ5en2exSg3aiY3tC29W4AlCqz+
 7aB1JWDFLnmCWPhBwjZYK9e3Od2+XqxTi6jggvIecuOP5wRkfLouZtw
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Delta E50SN12051 is a 600W non-isolated 1/8th brick DC-DC power module.
With this series applied, voltage, current and temperature sensors can 
be exposed through the standard hwmon interface.

Changes in this series:
- Introduce device-tree binding documentation for the new device
- Add hwmon documentation describing the supported sensors
- Add PMBus driver support for Delta E50SN12051

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
Changes in v4:
- Rewrite binding description to be hardware-centric and OS-agnostic.
- Rename example node from hwmon@40 to a generic power-module@40.
- Link to v3: https://lore.kernel.org/r/20260430-add-e50sn12051-v3-0-f6d4e043ec7c@gmail.com

Changes in v3:
- Simplify to pass &e50sn12051_info directly to pmbus_do_probe() 
  to avoid the extra memory allocation
- Link to v2: https://lore.kernel.org/r/20260430-add-e50sn12051-v2-0-d76fe42482ab@gmail.com

Changes in v2:
- Add %YAML 1.2 declaration in binding document.
- Use a generic node name in examples in binding document.
- Add MODULE_IMPORT_NS("PMBUS")
- Remove unused / incorrect headers
- Link to v1: https://lore.kernel.org/r/20260429-add-e50sn12051-v1-0-c101e6c80bbb@gmail.com

---
Colin Huang (3):
      dt-bindings: hwmon: pmbus: add Delta E50SN12051 binding
      Documentation/hwmon: add Delta E50SN12051 documentation
      hwmon: (pmbus) add support for Delta E50SN12051

 .../bindings/hwmon/pmbus/delta,e50sn12051.yaml     | 42 +++++++++++
 Documentation/hwmon/e50sn12051.rst                 | 81 ++++++++++++++++++++++
 Documentation/hwmon/index.rst                      |  1 +
 drivers/hwmon/pmbus/Kconfig                        |  9 +++
 drivers/hwmon/pmbus/Makefile                       |  1 +
 drivers/hwmon/pmbus/e50sn12051.c                   | 52 ++++++++++++++
 6 files changed, 186 insertions(+)
---
base-commit: b584e7d50af502462349910bf4ed30057620b69f
change-id: 20260316-add-e50sn12051-ad828ad6777a

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

