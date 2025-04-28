From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Subject: [PATCH 0/2] Add support for the DFRobot SEN0322 oxygen sensor
Date: Mon, 28 Apr 2025 12:50:12 +0200
Message-Id: <20250428-iio-chemical-sen0322-v1-0-9b18363ffe42@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAGRdD2gC/x3MQQqAIBBA0avErBuwSSu6SrRIG2ugLBQiiO6et
 HyL/x9IHIUT9MUDkS9JcoSMqizArVNYGGXOBlJklKYORQ50K+/ipg0TB1UTofOdt9Zya3QDOT0
 je7n/7TC+7wfFS4LRZgAAAA==
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745837432; l=803;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=bYzWEyx7wF1a4iH6jkzQs6rTKgOzlRhswyhO+IHRbag=;
 b=FX53BKRvsPXfLu9zX6oIbWxnJrO3cEa7YLggqBsOhEtfUwHaoMjdIw5SrfKzq3Iyj6hfpsfeF
 KpvfqlNujtWAihX3N9vNXNLBKI8rxrhFNNIPCIfJTOxZIw3LZ1C9F4N
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds a driver and the documentation for the
DFRobot SEN0322 oxygen sensor.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
Tóth János (2):
      dt-bindings: iio: chemical: Document SEN0322
      iio: chemical: Add driver for SEN0322

 .../bindings/iio/chemical/dfrobot,sen0322.yaml     |  41 ++++
 MAINTAINERS                                        |   6 +
 drivers/iio/chemical/Kconfig                       |  10 +
 drivers/iio/chemical/Makefile                      |   1 +
 drivers/iio/chemical/sen0322.c                     | 238 +++++++++++++++++++++
 5 files changed, 296 insertions(+)
---
base-commit: b4432656b36e5cc1d50a1f2dc15357543add530e
change-id: 20250428-iio-chemical-sen0322-cf8fbbbe7546

Best regards,
-- 
Tóth János <gomba007@gmail.com>

