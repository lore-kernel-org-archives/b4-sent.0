From: Kurt Borja <kuurtb@gmail.com>
Subject: [PATCH v3 0/2] platform/x86: alienware-wmi-wmax: Add support for
 GPIO methods
Date: Fri, 02 May 2025 05:08:59 -0300
Message-Id: <20250502-awcc-gpio-v3-0-ea9a932d1124@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJt9FGgC/02MwQ6DIBAFf8VwLg27gKY99T+aHhBRN6lioKFtj
 P9eND1wnJc3s7LoArnIrtXKgksUyc8Z5KlidjTz4Dh1mRkK1EKB5OZtLR8W8hxVC722WtUdsvx
 fguvpc7Tuj8wjxZcP3yOdYF//FSwrCbjgUAsD0FrZX8xtmAw9z9ZPbK8kLM2mNDGbtpEgG9nqT
 mBpbtv2A7a35ITcAAAA
X-Change-ID: 20250413-awcc-gpio-24b1f5c546d2
To: Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Armin Wolf <W_Armin@gmx.de>
Cc: Gabriel Marcano <gabemarcano@yahoo.com>, 
 platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1694; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=L/55x76jq/qiQEmKk7ejxbxAQIAOe3h5IfdGTNBl5v0=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBkitav2S5pG/troxzWzYR6HlKjlk5650qGtl/VCJ0xs0
 cr/9om1o5SFQYyLQVZMkaU9YdG3R1F5b/0OhN6HmcPKBDKEgYtTACbiYszIcNLy0cZoIbkV6TF7
 r1xyWV3K/XdyTYZsRIKnr033TKPb1gx/hSqeZS5/mPMrTdKr045nXh3Du9vGl1mEp7w5skxcYeI
 6ZgA=
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
Changes in v3:
- Create pinX files dynamically, based on GPIO pin count
- Added note on dummy input arguments in Documentation
- Link to v2: https://lore.kernel.org/r/20250427-awcc-gpio-v2-0-c731373b5d02@gmail.com

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
 Documentation/wmi/devices/alienware-wmi.rst     |  82 +++++++++++++++++-
 drivers/platform/x86/dell/alienware-wmi-wmax.c  | 105 +++++++++++++++++++++++-
 3 files changed, 201 insertions(+), 6 deletions(-)
---
base-commit: f618f1b298d3195d363b20f158ccb3facf553f0d
change-id: 20250413-awcc-gpio-24b1f5c546d2

Best regards,
-- 
 ~ Kurt

