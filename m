From: Sven Peter <sven@kernel.org>
Subject: [PATCH 00/11] Apple Silicon USB3 support - TIPD changes
Date: Sun, 14 Sep 2025 12:56:05 +0000
Message-Id: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGW7xmgC/x3MQQqAIBBA0avErBvQTMKuEi00pxoIE60IorsnL
 d/i/wcyJaYMffVAoosz76FA1hVMqw0LIftiaESjhZEt2hg3wjM7hQdHj9qITqvOS3IaShUTzXz
 /x2F83w/4AgR6YQAAAA==
X-Change-ID: 20250914-apple-usb3-tipd-5907537d1eb5
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, stable@kernel.org, 
 Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2202; i=sven@kernel.org;
 h=from:subject:message-id; bh=nhfs+mEuuE8OzOKQk+B9DPGOqq0cCbj6Jqm6nThYyu0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8ax3aUW55adaz7+q4BDcRbvi28b+jek9dwN2m74X2lF3
 NKtWp3nOkpZGMQ4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATWVXC8E+PPfVNaej1N/Of
 Pt3gnOkxMbrmtEtr/JMVaxL9nuRwpP1nZLhmYZByw/eBv4r7gVopj3CHjboTQxsaZpdurloVvak
 3gg0A
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series contains the required TIPD changes to support USB3 on Apple
Silicon machines and also prepares DisplayPort alternate mode and
Thunderbolt/USB4 support there.

As discussed in the series combining TIPD, DWC3, PHY, and DTS changes
this series contains only the TIPD changes which are already in a pretty
decent shape.

Link to v2 of the combined series: https://lore.kernel.org/asahi/20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org/
Changes since v2 of that series:
- Added r-b tags from Heikki and Neal
- Addressed Janne's feedback:
  - Updated the tipd commit description to match the dwc3 glue driver
    approach
  - Removed a stale comment left-over from a WIP version and no longer
    required
  - Cleared cd321x->state.data after typec_set_mode is done
  - Removed spurious NULL checks for typec_mux_put and typec_unregister_altmode
  - Call cd321x_connect instead of open-coding almost the same logic
    inside cd321x_interrupt

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Hector Martin (4):
      usb: typec: tipd: Update partner identity when power status was updated
      usb: typec: tipd: Use read_power_status function in probe
      usb: typec: tipd: Read data status in probe and cache its value
      usb: typec: tipd: Handle mode transitions for CD321x

Sven Peter (7):
      usb: typec: tipd: Clear interrupts first
      usb: typec: tipd: Move initial irq mask to tipd_data
      usb: typec: tipd: Move switch_power_state to tipd_data
      usb: typec: tipd: Trace data status for CD321x correctly
      usb: typec: tipd: Add cd321x struct with separate size
      usb: typec: tipd: Read USB4, Thunderbolt and DisplayPort status for cd321x
      usb: typec: tipd: Register DisplayPort and Thunderbolt altmodes for cd321x

 drivers/usb/typec/tipd/core.c     | 559 ++++++++++++++++++++++++++++++++++----
 drivers/usb/typec/tipd/tps6598x.h |   5 +
 drivers/usb/typec/tipd/trace.h    |  39 +++
 3 files changed, 550 insertions(+), 53 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250914-apple-usb3-tipd-5907537d1eb5

Best regards,
-- 
Sven Peter <sven@kernel.org>

