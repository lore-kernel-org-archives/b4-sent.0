From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v3 0/3] iio: temperature: ltc2983: small improvements
Date: Fri, 01 Mar 2024 18:14:49 +0100
Message-Id: <20240301-ltc2983-misc-improv-v3-0-c09516ac0efc@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAkN4mUC/x3MQQqAIBBA0avErBvIMUi7SrQom2ogLTQiiO6et
 HyL/x9IHIUTtMUDkS9JsocMXRbg1iEsjDJlA1VUV0QNbqcjazR6SQ7FH3G/cLKuHrRRdlQz5PK
 IPMv9X7v+fT+86InMZQAAAA==
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709313291; l=885;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=iU4ye3YD5mJYIMLDbIQUPxRF5RMbXybTMwbi1mW2Z9g=;
 b=SxIZfLh6ggzU9sPVChDLFPaB1wbTNwRMvddiUoVX1lYExajJS9DDvZjFioPAWgixGO2xiCaex
 XI7r7G0nsxTA5cNaHKBVQMxCu5CN0DkLjyRo3OEnzbBr5/2XJZ7VrPc
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

The quick v3 is only to fix the error in the bindings patch...

v1:
 * https://lore.kernel.org/all/20240222-ltc2983-misc-improv-v1-0-cf7d4457e98c@analog.com/

v2:
 * https://lore.kernel.org/all/20240229-ltc2983-misc-improv-v2-0-cc6f03da2529@analog.com/

v3:
 - Patch 2
   * Added vdd-supply to the dts example;

---
Nuno Sa (3):
      iio: temperature: ltc2983: convert to dev_err_probe()
      dt-bindings: iio: temperature: ltc2983: document power supply
      iio: temperature: ltc2983: support vdd regulator

 .../bindings/iio/temperature/adi,ltc2983.yaml      |   4 +
 drivers/iio/temperature/ltc2983.c                  | 267 ++++++++++-----------
 2 files changed, 131 insertions(+), 140 deletions(-)
---
base-commit: 74744b27ba8cb8c265263aa0ff0693350a8cbc19
change-id: 20240227-ltc2983-misc-improv-d9c4a3819b1f
--

Thanks!
- Nuno Sá

