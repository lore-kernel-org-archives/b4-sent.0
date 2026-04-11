From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Add initial dual front camera and rear flash support
 for Pixel 3 / 3 XL
Date: Sat, 11 Apr 2026 12:09:40 +0200
Message-Id: <20260411-pixel3-camera-v1-0-2757606515b6@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOQd2mkC/xWMQQqAIBQFrxJ/nZCJkV0lWlg960NZKEQg3j1bD
 sxMoojAiDRUiQIejnz5ArKuaNmt3yB4LUxt03aNklrc/OJQYrEnghXWmN7MTvcGoNLcAa4I/2+
 ccv4ApSSaSV8AAAA=
X-Change-ID: 20260315-pixel3-camera-a9989bf589ee
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=720; i=david@ixit.cz;
 h=from:subject:message-id; bh=WaCFPl3XCm6Cz48Zr/ZGAl7C9mBz7/lJfLbpnm+4jdU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp2h3oXvCHxfHsvG/CwaxqL2/mWITSitfi4XWYR
 BhxxiqRRHaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadod6AAKCRBgAj/E00kg
 cpXJEACHCSzG2x8gmQAjFjq1rmBPLnNdVh79fkRlo+YbDwNWmMaUehGeVxJyJQMewhNgzuOftvz
 bUqWFcj6h3zhZuOf/Xt2/ZA6PlyITgU0IJ0qL3HGSHZTxAIHMqeNxBYUSvgPx6brs7Il/KKdN0B
 KCTJ7fOHmeAl9/kJsck9WzaL31160LlSyvCaZ8mlsdRdwN0OLJWEjWtqQcuqmq+Ksn4eiJO8I1t
 iKzeYrw8r7W4q+ganxIsYtTdYNoMzm1p8i+BHGI2yWJ+TB1vtCIrTnHszViOoHunHyQB4VbbJfO
 fZECR6cE4tFps3rWXFf2JKR1fq3zW4HPx5fchJcI7sVtyxdV5JDM87jqLr36jSmvoaF6FaamGD5
 XfYQwG81rh05OB2WWo4pg1cypEqsQi2UE1+0vBghj8WvB35M7+H09SvLq6prI6wollNMj20m7XQ
 Wp3VjGVXkvBV6OT/5VRshgrRBpM0b77b7xQxu22SzpDHHynFzBkGBaTw/qVSQcYMnPznzhJDuw+
 X7ZqOISFvvBce+DOu9OGM92Ab9LfcTUfELInbZM0sYVo+FB2yVwZNKK8fL9CWjjqPnj535PPSFi
 1n3mwp2MzeVneocVn6MShHXY6QydDjKn5Vkb7DdlG5WZFB7xIibfBb3K4zJSYbV/19XYkdJ3zaD
 gh6fiyxJiAM5ucA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the dual front-facing IMX355 sensors (standard and wide)
and enable the PMI8998 flash LED with hardware-accurate limits.

This brings up the basic camera topology and flash support in DT.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      arm64: dts: qcom: sdm845-google: Add dual front IMX355 cameras
      arm64: dts: qcom: sdm845-google: Enable PMI8998 camera flash LED

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 200 ++++++++++++++++++++-
 1 file changed, 199 insertions(+), 1 deletion(-)
---
base-commit: db7efce4ae23ad5e42f5f55428f529ff62b86fab
change-id: 20260315-pixel3-camera-a9989bf589ee

Best regards,
-- 
David Heidelberg <david@ixit.cz>

