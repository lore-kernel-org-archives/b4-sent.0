From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH 0/2] Hi there,
Date: Mon, 17 Aug 2026 11:27:29 +0100
Message-Id: <20260817-for-next-lucky7-v1-0-42ffb2b71ba2@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABHigmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0NT3bT8It281IoS3ZzS5OxKc91U06Q0Y0tTg6SUpFQloK6CotS0zAq
 widGxEH5xaVJWanIJyBil2loAnoNuaHMAAAA=
X-Change-ID: 20260815-for-next-lucky7-e5bf3950bdbe
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik+git@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2106;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=f+Yhy4mCUFZnwR9Avc8QcKYxy2n2JxO8lpjuhASWq5k=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqguIVmBymH/hvV78jWokIS4novz0NaqNzuCSq6
 opqDD65f62JAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoLiFQAKCRBJJwGyxHrX
 6zgWEADmS1+Z7nmYpvit6j6ti/snKs4bL16HZUbVgsd2CG+W0lNT7bK2k5/csJiWrOWFsKsX1kV
 cIZ6QHdmZszN1FEepvRfcOME8uWPhuB28GW7WK7FoopnHlNLT/ALKjqyP//4aOA42PHIoIFep+R
 Et3huF9j2QqvQz6OZXiQ4tKyCVq6aqRZX0udEGj6rSkY54/lGoZ/9T1jRvvfJ77hfigkt5IL9FH
 ARYxL58Uc+mEA1w7MbOFhBKAPl4pU8NeCI4IUTxGpSdwvsdxkW9WsFcglPbZWhCXIFCEnLH6O1D
 1KKrkaPgRJh0EA5B9N2Y+a2AmL23qpH8qJNN7oAB3oL7PowsldYGLcXg2/oJa2JTxzpsWcJSsgv
 8WPXb5kQr0SzMl1rNl7riSh5TFMgCwcdrN0yYIiNv9Ju6mGvI/KIIs3AOU9341iqP8mdhKlFSgI
 w6d9C8N+YxK6rnH4fv4yVKYIT8JKqH7HrKdOC7Yb+S2zjRu+pYphZr4CgXq4blliWbEwKRPxbyc
 ZpLqlWX2w4u2f9Fuiu/n7YJDdkuZV4zGt5tB2tSV9wxZ3XcTFuNQElgDETnHrm5kUO+Rqkm1CtH
 Bh0Oi+/qd+JrOSCZ+oynmBlIwgD82Y+l/uD1mF8KkFXin/ZgP3SS92VtJd6hV9xHZl04mgnsPpN
 L/XfARzcnMaQL7Q==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds initial support for the Exynos 5515 SoC, along with
support for the Samsung Galaxy Watch FE (codenamed lucky7), which uses
this SoC.

Support for the following is added:
- Bootloader framebuffer
- Both CPU cores
- Memory
- Generic timer
- Watchdog timer
- CMU_TOP, CMU_FSYS, CMU_PERI clock management units
- ChipID

Only the lowest 490MiB and highest 512MiB of memory are used for now.
The 488MiB between the addresses of 0x9ea00000 and 0xbe680000 is excluded
from the memory node due to a bug where if the kernel even knows about
the existence of this memory, one or both cores will lock up and cause
an RCU stall. There are several regions between this addresses which will
lock up the core, so the issue is difficult to bisect, and attempting to
dump memory information on panic will just lock up the second core.

Currently, these device trees support booting the device to an initramfs.

I am getting checkpatch warnings on this patchset advising to check
MAINTAINERS as new files were added, but I assume they can be ignored
as I am not a maintainer.

This patchset depends on [1], [2], and [3], for drivers and device tree
bindings.

[1] https://lore.kernel.org/all/20260817-for-next-lucky7-chipid-v1-0-eb2908705c0d@member.fsf.org/
[2] https://lore.kernel.org/all/20260817-for-next-lucky7-clock-v1-0-032e4b229c76@member.fsf.org/
[3] https://lore.kernel.org/all/20260817-for-next-lucky7-watchdog-v1-0-a14370e20b92@member.fsf.org/

Kind regards,
- Aiden Isik

Signed-off-by: Aiden Isik <aidenisik+git@member.fsf.org>
---
Aiden Isik (2):
      arm64: dts: exynos: Add initial support for Exynos5515 SoC
      arm64: dts: exynos: Add initial support for Samsung Galaxy Watch FE

 arch/arm64/boot/dts/exynos/exynos5515-lucky7.dts | 106 +++++++++++++
 arch/arm64/boot/dts/exynos/exynos5515.dtsi       | 186 +++++++++++++++++++++++
 2 files changed, 292 insertions(+)
---
base-commit: add58997023d8fbf429745f8a2e25289bbe22885
change-id: 20260815-for-next-lucky7-e5bf3950bdbe

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

