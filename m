From: Nickolay Goppen <setotau@yandex.ru>
Subject: [PATCH 0/2] Add LPASS/CDSP vote clocks/GDSCs for SDM660
Date: Fri, 15 Aug 2025 19:56:50 +0300
Message-Id: <20250815-gcc-sdm660-vote-clocks-and-gdscs-v1-0-c5a8af040093@yandex.ru>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANJmn2gC/x3NwQqDMAyA4VeRnBeouoruVcYOXRJr2GxHM2Qgv
 vuKx+/y/zuYFBWDW7NDkU1Nc6poLw3QElIUVK6GznXeja3HSITG6zA43PJXkN6ZXoYhMUY2Mrz
 208w9PWkMHmrmU2TW37m4P47jD6fJg3RyAAAA
X-Change-ID: 20250815-gcc-sdm660-vote-clocks-and-gdscs-439fd3cbc8a5
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nickolay Goppen <setotau@yandex.ru>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755277013; l=748;
 i=setotau@yandex.ru; s=20250815; h=from:subject:message-id;
 bh=HElbIKK8aSTKmO/ZwAiZrBwwRzKY55uzVhucMeSfW5A=;
 b=1Y/v7jrQ+XTqQsZpbZdJh6yqm0HdBSkFxvGa3BEhEupM7VwzpKN4g5DA0elflLl/B5zP9XrZ+
 h8T7wWJRQssCLhVuMftAyCUKvFxQhxGwrHialySwjjUc14rK6yXvYN8
X-Developer-Key: i=setotau@yandex.ru; a=ed25519;
 pk=Og7YO6LfW+M2QfcJfjaUaXc8oOr5zoK8+4AtX5ICr4o=
X-Endpoint-Received: by B4 Relay for setotau@yandex.ru/20250815 with auth_id=492
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds LPASS/CDSP vote clocks/GDSCs to gcc-sdm660 driver.
These clocks are needed for properly functioning of SMMUs related to the
audio/compute DSPs.

Signed-off-by: Nickolay Goppen <setotau@yandex.ru>
---
Nickolay Goppen (2):
      dt-bindings: clock: gcc-sdm660: Add LPASS/CDSP vote clocks/GDSCs
      clk: qcom: gcc-sdm660: Add missing LPASS/CDSP vote clocks

 drivers/clk/qcom/gcc-sdm660.c               | 72 +++++++++++++++++++++++++++++
 include/dt-bindings/clock/qcom,gcc-sdm660.h |  6 +++
 2 files changed, 78 insertions(+)
---
base-commit: 1357b2649c026b51353c84ddd32bc963e8999603
change-id: 20250815-gcc-sdm660-vote-clocks-and-gdscs-439fd3cbc8a5

Best regards,
-- 
Nickolay Goppen <setotau@yandex.ru>

