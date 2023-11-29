From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v3 0/2] iio: dac: ad5791: Add support for controlling RBUF
 via devicetree
Date: Wed, 29 Nov 2023 14:03:51 +0100
Message-Id: <20231129-ad5791-michael-stuff-v3-0-48e192b00909@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIALc2Z2UC/x2MWwqAIBAArxL73UJqKnWV6CN0rYVeaEUQ3T3pc
 xhmHkgUmRK0xQORLk68rRlUWYCbhnUkZJ8ZZCWVENLi4LVtBC6cNc2YjjME1MZ4p41UtbeQ0z1
 S4Pvfdv37ftApwfxmAAAA
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Michael Hennerich <michael.hennerich@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701263126; l=643;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=HLyE4DFjg0ktNNqTQcSgMBS1cvWJrNgCeheSB7P/8TQ=;
 b=PF3K4AADVjxejkG643HZzUFSIwKaoOI72SmpbsCHZ9FEy1h0Skr/l+9fOlpTR9zx4Vaz13QbG
 PZFXzSINkszA8wZBxEu81tfcBgnTULS/6bKKReAut2P4wvzU6Nk16zy
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simple series to add support for an external amplifier to be connected
in again of two configuration.

v2:
 * removed .yaml suffix from commit title;
 * Don't use commit/patch in commit message.

v3:
 * Be more imperative in the commit message.

---
Michael Hennerich (2):
      dt-bindings: adi,ad5791: Add support for controlling RBUF
      iio: dac: ad5791: Add support for controlling RBUF via devicetree

 Documentation/devicetree/bindings/iio/dac/adi,ad5791.yaml | 5 +++++
 drivers/iio/dac/ad5791.c                                  | 9 ++++++++-
 2 files changed, 13 insertions(+), 1 deletion(-)

Thanks!
- Nuno Sá

