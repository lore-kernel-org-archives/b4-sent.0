From: Kurt Borja <kuurtb@gmail.com>
Subject: [PATCH v2 0/2] platform/x86: alienware-wmi-wmax: Add support for
 GPIO methods
Date: Sun, 27 Apr 2025 03:24:47 -0300
Message-Id: <20250427-awcc-gpio-v2-0-c731373b5d02@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK/NDWgC/03MQQ7CIBCF4as0sxbDUGiiK+/RdEEp0ElsacCgp
 uHuYuPC5f/y8u2QbCSb4NrsEG2mRGGtIU4NmFmv3jKaaoPgQnGJLdNPY5jfKDAhR3TKKNlNAup
 /i9bR67D6ofZM6RHi+6AzftefIv6VjIwz7LhGHE3rLvrmF033swkLDKWUD5r/8sGiAAAA
X-Change-ID: 20250413-awcc-gpio-24b1f5c546d2
To: Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Armin Wolf <W_Armin@gmx.de>
Cc: Gabriel Marcano <gabemarcano@yahoo.com>, 
 platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1473; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=SnRI4E+XNy8GG/C2Rg6Ulr3oImnQQogQ6gtX19wzy+g=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBm8Zw9//5QTbaPZ1HxRxurjnuzSKWL7n5pcWO+x7QvT3
 OKemSbRHaUsDGJcDLJiiiztCYu+PYrKe+t3IPQ+zBxWJpAhDFycAjCRCbUM/zN1edYYK16XShHd
 rGk2d+KJfd9mXrkRL/DpN/sJjvl/3NYyMjzvPab+Za9hoNG5+N8cxbaBSdsD2WcY3lj3+51RR+z
 zMAYA
X-Developer-Key: i=kuurtb@gmail.com; a=openpgp;
 fpr=54D3BE170AEF777983C3C63B57E3B6585920A69A
X-Endpoint-Received: by B4 Relay for kuurtb@gmail.com/default with auth_id=387
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

I found a great blog post [1], which described the reverse engineering
process of the GPIO control methods present on this device.

In summary, these methods expose some debugging capabilities of the RGB
lighting controller present on Dell gaming laptops. See [Patch 2] for
more info.

Exposing these methods to DebugFS is useful for developers exploring
this RGB controllers (myself included).

Thanks for your feedback!

[1] https://gabriel.marcanobrady.family/blog/2024/12/16/dell-g5-5505-se-acpi-or-figuring-out-how-to-reset-the-rgb-controller/

Signed-off-by: Kurt Borja <kuurtb@gmail.com>
---
Changes in v2:
- Dropped module parameter
- Added ABI documentation to Patch 1
- Small improvements to documentation based on Armin's comments
- Improved Pin description table format
- Link to v1: https://lore.kernel.org/r/20250423-awcc-gpio-v1-0-160a11bc3f9a@gmail.com

---
Kurt Borja (2):
      platform/x86: alienware-wmi-wmax: Expose GPIO debug methods
      Documentation: wmi: alienware-wmi: Add GPIO control documentation

 Documentation/ABI/testing/debugfs-alienware-wmi |  20 +++++
 Documentation/wmi/devices/alienware-wmi.rst     |  78 ++++++++++++++++-
 drivers/platform/x86/dell/alienware-wmi-wmax.c  | 108 +++++++++++++++++++++++-
 3 files changed, 201 insertions(+), 5 deletions(-)
---
base-commit: 981527828c301644bc4014faa9c523e8a5e32a32
change-id: 20250413-awcc-gpio-24b1f5c546d2

Best regards,
-- 
 ~ Kurt

