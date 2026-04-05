From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] arm64: dts: qcom: beryllium compatible ordering and
 bindings update
Date: Sun, 05 Apr 2026 12:54:54 +0200
Message-Id: <20260405-beryllium-compat-string-v2-0-91149be07835@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH4/0mkC/4WNTQ6CMBBGr0Jm7ZihAkldeQ/Doi0VJuEvbW1A0
 rtbuYDL95LvfQd469h6uBcHOBvZ8zJnEJcCzKDm3iJ3mUGQaKiiG2rr9nHk94RmmVYV0AfHc4/
 GlJXUkpSQHeT16uyLt7P8bDMP7MPi9vMolj/7vxlLJCTVaGl0XStBD944XM0H2pTSFyb4nE28A
 AAA
X-Change-ID: 20260403-beryllium-compat-string-cc149b90a29d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>, 
 Jens Reidel <adrian@travitia.xyz>, Arnaud Ferraris <aferraris@debian.org>, 
 Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Petr Hodina <petr.hodina@protonmail.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1958; i=david@ixit.cz;
 h=from:subject:message-id; bh=U0Y1dfa7x6ljrvRF5AHYokovzfPc9zay7BPLdG5hFFM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp0j9/68wXsw1fCSjwwwXOmquRH96atpAGySsNC
 sck70xjcqCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadI/fwAKCRBgAj/E00kg
 ciBjD/99lAVSgOfOneAV7cN506+okqDnFUa2DbWO2Br86UfEgnyz0Q1lZ1Jvve1b8RXCkgIQJPe
 SqDUwr1FjZn7zXE+deleK8bmva8l3RuEeF8mu4I8XFamtEfNTxJSm0tav2mHyLSLSmw71gLgjiN
 9Oln98EplrFqBkPjABsZl7YXNwQ1majNgY6GenWeb8aHj+Ryh914GE2lQ7YsdCwFbypusd1/7gB
 xPSs/ZCP1ZqN0VowTPNnnVM8z7xoJuRfjKI1UzJlI2jYIzjjkfNDhoVHVzRRy4RuzLozhDAmmhC
 Pp3c9+P9oyFWoMmXbcFbcm5bBqZdPtM8XFtZnWX/m4ua+A9zf2siFcoFtsbz73HM2M3qQ/Q4gIj
 tAbeNxPbkVbQvpLeg0bVJ/2uHEwt671FSyNm6y7XTjheK15uU4KUK2XHEGvY7hPDKQQxil2Zl8p
 Ny/bp2Mo2h1Imq87XBrylBrF3U7p3M5eO5Tvc7Jgl3UsUNEZLyGRcIxQAevkgRkdQ3RhxKB4Kab
 pCKOc0JdMd7X1VgzuPKAiDNJP3sVMAVXsNnioZuxgRe1MTN+5Arm3v7hrlJYsW/4P6ql43oCiTF
 SoKWHSYeQkTLP9BjJXR4mT0KhyfLZ+JrD9RX13RmEBswW9ACmkXTRNAfZD3C4xplwuEStKsQA/F
 9t5rInMB/nXn6WA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series aligns the Xiaomi Poco F1 (beryllium) device tree
compatible strings with DT matching rules by ensuring proper
fallback to the generic device compatible.

Patch 1 updates the dt-bindings documentation to describe
the Tianma panel variant and clarify the expected compatible
string ordering and fallback requirements, aligning the
binding with actual DTS usage.

Patch 2 updates the DTS files to append the generic
"xiaomi,beryllium" compatible after the panel-specific ones.
This enables correct userspace fallback matching (e.g. for
hexagonrpcd), which currently fails when only the variant-
specific compatible is present. This constitutes a DT ABI
change, as additional compatible matches become possible.

Together, these changes fix an incomplete compatible chain
and ensure consistent behavior across panel variants.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- To be extra safe, CCed Arnauld and Marco (Mobian), Jens (for pmOS) is
  already in the loop, Petr (for NixOS Mobile is already in the loop).
- Improved description and documented that main distributions
  already use the patch (thus no API break will not happen to these
  projects).
- Link to v1: https://lore.kernel.org/r/20260403-beryllium-compat-string-v1-0-0a6b9cb55a20@ixit.cz

---
David Heidelberg (1):
      dt-bindings: arm: qcom: Document Xiaomi Poco F1 Tianma variant

Jens Reidel (1):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Append compatible strings

 Documentation/devicetree/bindings/arm/qcom.yaml             | 10 ++++++++--
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts   |  2 +-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts |  2 +-
 3 files changed, 10 insertions(+), 4 deletions(-)
---
base-commit: cc13002a9f984d37906e9476f3e532a8cdd126f5
change-id: 20260403-beryllium-compat-string-cc149b90a29d

Best regards,
-- 
David Heidelberg <david@ixit.cz>

