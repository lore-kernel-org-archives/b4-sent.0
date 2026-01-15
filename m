From: Shrikant Raskar <raskar.shree97@gmail.com>
Subject: [PATCH v5 0/5] iio: proximity: Add interrupt support for RFD77402
Date: Thu, 15 Jan 2026 13:57:36 +0530
Message-Id: <20260115-rfd77402_v5-v5-0-594eb57683e4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPikaGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyTHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQ0NT3aK0FHNzEwOj+DJTXdMUQzPTJKPUxJRECyWgjoKi1LTMCrBp0bG
 1tQAGhsn6XQAAAA==
X-Change-ID: 20260115-rfd77402_v5-5d165b2eada8
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: skhan@linuxfoundation.org, david.hunter.linux@gmail.com, 
 raskar.shree97@gmail.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768465693; l=2922;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=TD0CKqKvYK6A8K4BW0oFhjlCzyxkS+4b/3agMVvwxlQ=;
 b=DDRfls7lm9wPJ9qaKzpoJH66SkdxFA9mAHwXnWF6MXMusz+kzW1AzOnbXLCgKgT5S9qfTny2s
 M3QkoaaxdqrBSSodzVNxv5FAF5c1uyROux27KBZqRrOipZ0FUH3O7g6
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series improves the RFD77402 ToF driver by cleaning up include
ordering, improving resource lifetime handling, switching to kernel
polling helpers, and adding optional interrupt-driven operation.

Changes in v5:
- Add precursor patch to reorder includes before functional changes.
- Use devm_mutex_init() for proper lifetime management.
- Address maintainer feedback on polling helper usage.
- Remove dead code from interrupt_handler.
- Add blank line in rfd77402_wait_for_irq.
- Update measurement timeout comment.
- Add helper function for result polling.
- Fix comment format in rfd77402_init.
- Remove 'data->irq_en = false', as it already initialized by kzalloc.
- Improve documentation of private driver data.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
Changelog:

v3 to v4:
- No code change.
Link to v3: https://lore.kernel.org/all/20251221083902.134098-1-raskar.shree97@gmail.com/

v2 to v3:
- Add 'Reviewed-by' tag to dt-binding patch.
- Update commit message in OF device ID patch.
- Update commit message in the third patch.
- Replace rfd77402_result_polling() with read_poll_timeout().
- Add 'struct rfd77402_data' details in kernel-doc format.
- Arrange includes in order.
- Add comment for completion timeout value.
- Remove blank lines.
- Indent the comments to code.
- Convert mutex_init() to devm_mutex_init().
- Remove 'IRQF_TRIGGER_FALLING' flag from devm_request_threaded_irq().
- Drop the duplicate message.
- Replace 'dev_info' with 'dev_dbg()'.
- Update 'dev_id' to 'pdata' in rfd77402_interrupt_handler().
- Drop 'interrupt mode' comment
- Use 'if(ret)' instead of 'if(ret < 0) for consistency.
- Use 'return i2c_smbus_write_byte_data()' in 'rfd77402_config_irq'.
Link to v2: https://lore.kernel.org/all/20251130153712.6792-1-raskar.shree97@gmail.com/

v1 to v2:
- Fix commit message for dt-binding patch
- Update interrupt description in dt-binding
- Add 'vdd-supply' to 'required' property in dt-binding
- Add patch for moving polling implementation to helper
- Add helper rfd77402_wait_for_irq()
- Code refactoring
- Return failure if request IRQ fail
Link to v1: https://lore.kernel.org/all/20251126031440.30065-1-raskar.shree97@gmail.com/
---

---
Shrikant Raskar (5):
      iio: proximity: rfd77402: Reorder header includes
      iio: proximity: rfd77402: Use kernel helper for result polling
      iio: proximity: rfd77402: Add interrupt handling support
      iio: proximity: rfd77402: Use devm-managed mutex initialization
      iio: proximity: rfd77402: Document device private data structure

 drivers/iio/proximity/rfd77402.c | 157 +++++++++++++++++++++++++++++++++------
 1 file changed, 133 insertions(+), 24 deletions(-)
---
base-commit: 40e81d379e69d6db147865eee0c89e41634e0b60
change-id: 20260115-rfd77402_v5-5d165b2eada8

Best regards,
-- 
Shrikant Raskar <raskar.shree97@gmail.com>

