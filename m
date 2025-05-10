From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH 0/7] Support exposing bits of any byte as NVMEM cells
Date: Sat, 10 May 2025 07:44:40 +0000
Message-Id: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOgDH2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDUwML3byy3NRc3ZQS3ZRUw0RDCxOjVAsLYyWg8oKi1LTMCrBR0bG1tQD
 ysA7VWgAAAA==
X-Change-ID: 20250508-nvmem-dt-de1a1842e883
To: Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>, R <rqou@berkeley.edu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1867; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=CUo/MimrCW1xHj5d7fHDtNMddbwaaGdTDWDyY+tLI84=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4Y886+JhUwn/3XVWSgdXLxSLkhOtF73koo070H5hzV9l
 sqLejk7SlkYxDgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABMpF2b4K/xC+RXPE+Plrf6O
 8U5L98/5yRi1snSb6Ukhv1e+M3wP+DMyzC4UmveQ9UfFm/Qf//fd1WmRubpx9tnEs/vKKqM4DW5
 v4QMA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

I'm preparing USB3 support for Apple Silicon Macs for upstreaming right
now and this series is the first dependency. The Type-C PHY requires
configuration values encoded in fuses for which we already have a
driver.
Unfortunately, the fuses on these machines are only accessibly as 32bit
words but the Type-C PHY configuration values are individual bits which
are sometimes spread across multiple fuses.
Right now this is not supported by the nvmem core which only allows a
subset of bits within the first byte to be exposed as a nvmem cell. This
small series adds support for exposing arbitrary bits as nvmem cells.

The second part of the series then adds the nvmem cells required for the
Type-C PHY to our device trees. While it's technically independent I've
included those changes in this series for context.

Best,

Sven

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
Janne Grunau (2):
      Revert "nvmem: core: Print error on wrong bits DT property"
      arm64: dts: apple: t8112: Add eFuses node

R (1):
      arm64: dts: apple: t600x: Add eFuses node

Sven Peter (4):
      nvmem: core: allow bit offset > 8
      nvmem: core: round up to word_size
      dt-bindings: nvmem: apple: Add T8112 compatible
      arm64: dts: apple: t8103: Add eFuses node

 .../devicetree/bindings/nvmem/apple,efuses.yaml    |   1 +
 arch/arm64/boot/dts/apple/t600x-dieX.dtsi          | 187 +++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8103.dtsi               | 102 +++++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi               |  97 +++++++++++
 drivers/nvmem/core.c                               |  24 +--
 5 files changed, 401 insertions(+), 10 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250508-nvmem-dt-de1a1842e883

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

