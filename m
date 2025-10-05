From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Add support for Pixel 3 and Pixel 3 XL
Date: Sun, 05 Oct 2025 15:16:27 +0200
Message-Id: <20251005-pixel-3-v1-0-ab8b85f6133f@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKxv4mgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0NL3YLMitQcXWNdU0PD1JRko0QTMwNzJaDqgqLUNKAUyKTo2NpaAP5
 i8odZAAAA
X-Change-ID: 20250419-pixel-3-511edc2a4607
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Amit Pundir <amit.pundir@linaro.org>, Casey Connolly <casey@connolly.tech>, 
 Joel Selvaraj <foss@joelselvaraj.com>, 
 Sumit Semwal <sumit.semwal@linaro.org>, Vinod Koul <vkoul@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1721; i=david@ixit.cz;
 h=from:subject:message-id; bh=4jB+u25ZMhXJQ2J8eJP4a57jtjByDue+5wvNNt8Pq/o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo4m+vPHSg6W3fWjcWMLLcQyC/6TtbZGV0hPfCw
 P8eW4HgCoKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaOJvrwAKCRBgAj/E00kg
 cvSlD/9nGXHqAA18DOslR00OvsErto7Xr1SozQ2Adfb3GfXUcz4DIArCX5ux7eXs0sZEYop31u6
 Hcthkb8EJM2oSrDmuWPKMjmBOguzYmda8iogqARV7tCxlaXD/O9edF9mF/j70uLWsCX07zhbda/
 ttehxZ5NhQi09Hq3hjh6tNRZ3SbQdtlCrGPnG/irh4Sikhbv8ONU6PnGIdwH1rKd4w81n+pcaBG
 Uf/b3FMtq0SpdiVFp7FAiXw25r7n4UdohyrgpZCTnsi0Cs8gZzreATOsXr8/iFSgz6u1ufUthg3
 AVs2QWF+IwJvOKK06DS01ckLZwtV8cGwIRVYGndsZU9ZO8/YlrtLL/NsBm5gVbQHeOl7f2GUNIi
 /ztkpuebfBreIUBIltmqy462hrzmZ0zswtb8M+RzbtmhGYIrJMPUqYyjF+NP+liemvQ8MLbN2ZO
 iJ2kJTXAa/Y3sG6ACmCISwrd6Cr6pJXKMd8hXgzuiC8qwCmDsi+pnD3DuzGfytv9AK/IF0QzUFN
 41pOJ2vtSgjKr2QjB2xaUGVMl4C64VkmjKL+t55SDTgHffJepLUSB5ffy1fzzN9aBplhwn9cOp2
 xx3c3Qhi+70lRwEkpLRt8fLuroD/asTp9MOXQx/VBPmJug0K77CW8ijPL9gQc5xWPtjI3wHerVG
 Zc7C0Zyg3YsTxEA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds initial device tree support for the following phones:

 - Google Pixel 3 (blueline)
 - Google Pixel 3 XL (crosshatch)

Both phone boards use the same identifiers and differ only slightly
in their connected peripherals.

Supported functionality includes:
 - Debug UART
 - UFS
 - Charger
 - USB-C (peripheral mode)
 - Display (Pixel 3 only)

This is mainly focused to get the base functionality of the board and
being able to use the upstream DTS within Linux and u-boot.

Booting
-------
For older Pixel 3 bootloaders, bootloader-compatible board and MSM IDs are
required for the kernel to boot, so these have been added.

For recent Pixel 3 bootloaders,
a) you want chainloaded proper bootloader (f.e. u-boot),
b) you can also boot kernel when adding back TEXT_OFFSET
   (partial revert of 120dc60d).

This series is a beggining of cleaning up and transitioning support from
sdm845 close to mainline tree to the mainline.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      Documentation: dt-bindings: arm: qcom: Add Pixel 3 and 3 XL
      arm64: dts: qcom: Add support for Pixel 3 and Pixel 3 XL

 Documentation/devicetree/bindings/arm/qcom.yaml    |   5 +-
 arch/arm64/boot/dts/qcom/Makefile                  |   2 +
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts | 128 ++++++
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 467 +++++++++++++++++++++
 .../boot/dts/qcom/sdm845-google-crosshatch.dts     | 137 ++++++
 5 files changed, 736 insertions(+), 3 deletions(-)
---
base-commit: e5f0a698b34ed76002dc5cff3804a61c80233a7a
change-id: 20250419-pixel-3-511edc2a4607

Best regards,
-- 
David Heidelberg <david@ixit.cz>

