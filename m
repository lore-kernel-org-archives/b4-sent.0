From: Shrikant Raskar <raskar.shree97@gmail.com>
Subject: [PATCH v4 0/4] iio: proximity: Add interrupt support for RFD77402
Date: Thu, 01 Jan 2026 21:47:37 +0530
Message-Id: <20260101-b4-rfd77402_irq-v4-0-42cd54359e9f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACGeVmkC/x3MTQqAIBBA4avErBMmlYSuEhGaY82mnxEiCO+et
 PwW772QSZgyDM0LQjdnPvYK2zawbH5fSXGsBo26xw47FaySFJ2zqGeWS5kYfR980sYh1OoUSvz
 8x3Eq5QNLQss4YQAAAA==
X-Change-ID: 20260101-b4-rfd77402_irq-3dda6baf2370
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: raskar.shree97@gmail.com, skhan@linuxfoundation.org, 
 david.hunter.linux@gmail.com, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767284290; l=2057;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=uKMD+YVerNdxBNPgulQjVdLKZtk3V9JT3BlPXYGr/IM=;
 b=QeBOXo7QsqTkrTgk2V4poG9kBTJvzCdU4jyE/bmrqDdzRTYLWqw/gnH3IbgI2UydC8unw7f3Q
 Dv/AMHop7ULBrKzR938Qp6AvVvcA06b0/BSEMhAHe7IYkeds5umHHst
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds:
 - Add RF Digital vendor prefix
 - YAML binding for RFD77402
 - Add OF device ID for enumeration via DT
 - Use kernel helper for result polling
 - Interrupt handling support

These changes enable DT-based configuration and event-driven
operation for the RFD77402 Time-of-Flight sensor.

Changelog:
- Resend the patch series as v4 since not all patches were delivered
in v3 due to SMTP daily sending limits.
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

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
Shrikant Raskar (4):
      dt-bindings: iio: proximity: Add RF Digital RFD77402 ToF sensor
      iio: proximity: rfd77402: Add OF device ID for enumeration via DT
      iio: proximity: rfd77402: Use kernel helper for result polling
      iio: proximity: rfd77402: Add interrupt handling support

 .../bindings/iio/proximity/rfdigital,rfd77402.yaml |  53 ++++++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 drivers/iio/proximity/rfd77402.c                   | 149 ++++++++++++++++++---
 3 files changed, 183 insertions(+), 21 deletions(-)
---
base-commit: d8ba32c5a460837a5f0b9619dac99fafb6faef07
change-id: 20260101-b4-rfd77402_irq-3dda6baf2370

Best regards,
-- 
Shrikant Raskar <raskar.shree97@gmail.com>

