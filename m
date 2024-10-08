From: Joel Selvaraj <foss@joelselvaraj.com>
Subject: [PATCH 0/3] Add Xiaomi Poco F1 touchscreen support
Date: Mon, 07 Oct 2024 21:59:25 -0500
Message-Id: <20241007-pocof1-touchscreen-support-v1-0-db31b21818c5@joelselvaraj.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA2gBGcC/x3MQQqDQAwAwK9IzgZ2Q1vBr0gPEmPNZbMkWgTx7
 116nMtcEOIqAWN3gctXQ6005L4D3ubyEdSlGSjRI6c0YDW2NeNuB2/BLlIwjlrNd+ThSXN+ES9
 M0ILqsur5z6f3ff8AhCZNdGwAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joel Selvaraj <foss@joelselvaraj.com>, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>, Joel Selvaraj <jo@jsfamily.in>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728356389; l=1209;
 i=foss@joelselvaraj.com; s=20241007; h=from:subject:message-id;
 bh=rGIhUZq1OIxQBgv47TJ2KRLmsrhF54gP2FImUbG5WxM=;
 b=Fl+P5tK2HKXeuCQYn6cyNaeJn/xLqsmBsmpzVI44xGA9DUcKVhl6Qo8siQ2aiHR3O8R2TiJMH
 TjrxdBd9YLoDMC6mxGzBu8w/loaUKs66mLk6wN6nAXr/8LUSjwEiKni
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=pqYvzJftxCPloaoUbVsfQE7Gwv8bynZPy8mjYohwMCc=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20241007 with auth_id=238
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the first patch, I have enabled the  qupv3_id_1 and gpi_dma1 as they 
are required for configuring touchscreen. Also added the pinctrl configurations.
These are common for both the Poco F1 Tianma and EBBG panel variant.

In the subsequent patches, I have enabled support for the Novatek NT36672a
touchscreen and FocalTech FT8719 touchscreen that are used in the Poco F1
Tianma and EBBG panel variant respectively.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
Joel Selvaraj (3):
      arm64: dts: qcom: sdm845-xiaomi-beryllium-common: add touchscreen related nodes
      arm64: dts: qcom: sdm845-xiaomi-beryllium-tianma: introduce touchscreen support
      arm64: dts: qcom: sdm845-xiaomi-beryllium-ebbg: introduce touchscreen support

 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 39 ++++++++++++++++++++++
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts | 23 +++++++++++++
 .../dts/qcom/sdm845-xiaomi-beryllium-tianma.dts    | 23 +++++++++++++
 3 files changed, 85 insertions(+)
---
base-commit: d435d1e92be5fd26cd383fbddb596942ddc52b9f
change-id: 20241007-pocof1-touchscreen-support-c752a162cdc2

Best regards,
-- 
Joel Selvaraj <foss@joelselvaraj.com>

