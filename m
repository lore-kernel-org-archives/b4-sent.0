From: Sven Peter <sven@kernel.org>
Subject: [PATCH 0/2] dt-check-style support for indented include fragments
Date: Sun, 30 Aug 2026 20:24:53 +0200
Message-Id: <20260830-b4-dts-check-fix-v1-0-e7c1b2774730@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrB2IUdrqVcRFkpnWqaCSsUUQ7
 27U5ffg/RsoR2GFJtsg8l9UpjGhyDMIvRs/jELJYI19mFdp0FdIi2LoOQz4lhXJ17X1zrgnEaT
 bHDnNV7LtbuvPfzksZwf2/QDYZuBadAAAAA==
X-Change-ID: 20260830-b4-dts-check-fix-db992ba0a7dd
To: Rob Herring <robh@kernel.org>, Saravana Kannan <saravanak@kernel.org>
Cc: Daniel Golle <daniel@makrotopia.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, asahi@lists.linux.dev, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1486; i=sven@kernel.org;
 h=from:subject:message-id; bh=FIAqnorCi9b6ZDIiLe2fPgLdT+wwdwn3qsmraTcLNp4=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aU0oqa+vqt1nl+H7ySd7e5F3vVP+Xf5jczY4Edx5v7B
 QZ6hpM6SlkYxLgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABO5pcPIsGXFjUDm/EcMzXcC
 ytxTrx49/N7AuGS7y74NjI8XHuLMP8rw3/Fg11PRtJNiHxji71te4rF5OiNLIM0/8PN3N+ec8GZ
 LfgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Some .dtsi files are included from inside a node and carry the
indentation of that context. This is e.g. used for the multi-die
Apple SoCs and dt-check-style currently interprets that as part
of the indent unit and reports spurious warnings for otherwise
correctly indented Apple and Broadcom fragments.

Teach indent-unit-dts to detect and validate the inherited prefix and
make indent-consistent account for it as well. Also add fixtures to
test this.

With this all arm64 device trees pass the relaxed checks.

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (2):
      dt-check-style: Handle indented fragments in indent-unit-dts
      dt-check-style: Handle indented fragments in indent-consistent

 scripts/dtc/dt-check-style                         | 72 +++++++++++++++++-----
 .../dt-style-selftest/bad/dts-fragment-indent.dtsi | 12 ++++
 .../bad/dts-fragment-missing-prefix.dtsi           |  6 ++
 .../bad/dts-indented-ref-node.dtsi                 |  6 ++
 .../expected/dts-fragment-indent.dtsi.txt          |  3 +
 .../expected/dts-fragment-missing-prefix.dtsi.txt  |  2 +
 .../expected/dts-indented-ref-node.dtsi.txt        |  2 +
 .../dtc/dt-style-selftest/good/dts-fragment.dtsi   | 19 ++++++
 8 files changed, 106 insertions(+), 16 deletions(-)
---
base-commit: a23cbb05744b22719efdc34f9e329a120e81e617
change-id: 20260830-b4-dts-check-fix-db992ba0a7dd

Best regards,
--  
Sven Peter <sven@kernel.org>

