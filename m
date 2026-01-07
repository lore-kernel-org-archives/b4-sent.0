From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/2] Introduce Pixel config fragment for chainloading
 u-boot
Date: Wed, 07 Jan 2026 21:28:14 +0100
Message-Id: <20260107-pixel-config-v3-0-02a25e3fdcfa@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN7BXmkC/12MQQ6CMBBFr2K6tmRmoAKuvIdxAWWASQyQljQo4
 e62bkxcvv/z3q48O2GvrqddOQ7iZZ4i5OeTsmMzDayli6wI6AIIpV5k46e289TLoIsWTMXWFoy
 tisriuI9/yt0fkUfx6+xe33rAtKaQgZJqhLw2kCGaAgrQpLsmSHeTTdbMvlWyA/2MCggAc1Nnh
 ERR1vhvHMfxARwKWCXPAAAA
X-Change-ID: 20260107-pixel-config-4b058ecc4e1b
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de, Petr Vorel <petr.vorel@gmail.com>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, Simon Glass <sjg@chromium.org>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Matthew Croughan <matt@croughan.sh>, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1527; i=david@ixit.cz;
 h=from:subject:message-id; bh=3SzK7zFNN2411j+CdvliX/rSTfJSXnP/60IXCawXpqg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpXsHgu96s46mCrxnpGsffw4TgllkxFfuWTq5+3
 iwbEQc5CqCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaV7B4AAKCRBgAj/E00kg
 cpSqEADSu2qQuMc1MVOasA0CHhgfMV/kLoPVKLLZilp35ax//QRKLWCxPW+IgvXKfaKIsttQcMw
 o2OV+MFld7FZqyFgH91vpxnCCDqYqyAfGaHTbiSh3OYiczaZgvzaL12ltRYmjoozBiRrqVYbJOV
 EDE8XzbMWPRGy24rt+dGROHQj1eO3iBkx+ZLmd5fxgvA1pfIhvvZlTcJzxa//mgGyBBIhBLDY8r
 Anwv8mxcM+3v18lCPrcIUhK7haLVQhrc+LPim9Nqxg6/9rgqCYfeU/pvxoV508v1BnOhlNmnPxb
 +CQvSq2k28AWQTNGwo6jichmbID8WRQUlPabluUoGW5FRWokx89BdJixzyjjrmFWb2WdDbG6WpC
 M9qqdpEvqSlO7vjxKDF2bSoVMwlpecdkAzgfWdO/uBOh4b94zPApi5s3QJnw5OjKDxJYosWobHw
 vukify/BZa/llOL2Ew4mE/xOzqKonWVcxFqORjGOS5iHp7/UhlKCud0uFpVFEskjeWP3u+sq9hI
 kP3FhqcxkGwz3mFQ18/EutW+8N6URCKbfRcSohj4KX7TlT1cJq9+cIftAKaGUu2uiQ/DsccWPme
 oTWcqogBMNU6nQFQFGIy18KXaDGv1wmvdfnq9QFtCj7bP54q1dErhcG8M5kxznm61SPiCZ+UDJO
 /Cp4Hp3s/1f9UpQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Snapdragon Google Pixel bootloaders require the TEXT_OFFSET to be
exactly 0x80000. Without this, U-Boot or kernels will fail to load.

This patchset documents Pixel 3 and Pixel 3 XL and adds the necessary
config fragment along with usage instructions.

It has been tested on Pixel 3, 3 XL (by me), and Pixel 5 (by Petr Vorel).

The corresponding DTS files (sdm845-google-blueline and crosshatch) have
already been merged into the Linux -next, so mainline U-Boot will receive
these devices support soon.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Renamed google-pixel3.config to google-pixel.config as it's not
  limited to Pixel 3 / 3 XL, but also 5 and possibly others.
- Reworked the documentation. (Casey)
- Reworded commit message. (Casey)
- Link to v2: https://lore.kernel.org/u-boot/20250802001359.2122103-1-david@ixit.cz/

Changes in v2:
- Added documentation of Pixel 3 / 3 XL into doc/board/qualcomm. (Casey)
- Link to v1: https://lore.kernel.org/u-boot/20250729103950.1154040-2-david@ixit.cz/

---
David Heidelberg (2):
      doc: board: qualcomm: document Pixel 3 / 3 XL support
      configs: Add google-pixel fragment config for Pixel 3, 3 XL, 5

 board/qualcomm/google-pixel.config |  5 +++++
 doc/board/qualcomm/board.rst       | 20 ++++++++++++++++++++
 2 files changed, 25 insertions(+)
---
base-commit: 53c0d5b387956bb4070a943b61991898373a20e2
change-id: 20260107-pixel-config-4b058ecc4e1b

Best regards,
-- 
David Heidelberg <david@ixit.cz>

