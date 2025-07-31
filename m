From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v6 0/2] Add support for sound profile switching and
 leverage for OnePlus 6 slider
Date: Thu, 31 Jul 2025 23:17:00 +0200
Message-Id: <20250731-op6-tri-state-v6-0-569c25cbc8c2@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEzdi2gC/3WOQQ6CMBBFr2JmbUmntBRdcQ/DguAIkxhq2tqAh
 Ltb2Llw+Sbvv8wKgTxTgOtpBU+JA7spQ3U+QT9200CC75lBSWWkxotwr0pEzyLELpKgO3bSdIi
 oDOTNy9OD56N3azOPHKLzy5FPer9C7xL5AitrpVIadTFwLIJbyDfsn8X4hn2Yyl+5qo2s8fJHN
 of858dkhBRal6istLVB2/CcK/0H2m3bvl/SvYkCAQAA
X-Change-ID: 20250419-op6-tri-state-ed1a05a11125
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, Gergo Koteles <soyer@irl.hu>, 
 David Heidelberg <david@ixit.cz>, Casey Connolly <casey@connolly.tech>, 
 Konrad Dybcio <konradybcio@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1495; i=david@ixit.cz;
 h=from:subject:message-id; bh=8SuWb864/uWU83a12ckbpPsM3Uhs8t6j416NiF5XSpI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoi91NepPoeRso0VfQsB9G3tgPSIydZzZaZ3VgN
 BDzr3Shw0GJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIvdTQAKCRBgAj/E00kg
 cgimEADPsbp2OaDvw/jFddmwrciOXrdq50N8DxtkY7kMlIpJjqVltG3L2ezKBx3wKNlk5bInzcZ
 0iGqryZk7wJfvduW/PqEeqRaYeAcxOsBiNdbNknmgr09uNhlmHmFaYS9fWo8RbQHHzoQEcM9qrz
 dWmaR3XJTc7Gdf9lVuDo8CfS0YAI4GWcwlTvXakvlTI52XvL9uMNC4frPhrLwU68oRwvHcd7N9c
 dyabiTU0dikGbktk0vmh2cL1JC/eAxUFs2cdXAhZUwafvj3bJB9ESkmwRhKbBYUBpnnCHXWS0DG
 /+S3fcXomsocjBfNvPh0tea3yLFWzi1RVCAM6+W5d2Sa9pTz3aWCSmLPe6otOm1EVdENMo1hoNZ
 yBlGiS7Q3xQbiQ4MzA1yYl6yuUn1BGkkkF+7jScd32BF1vQucnigwJSRKAEdrRr5hspB4/UVpQt
 /YIRuE0eX7Gxe6VIahN2XwyaYvaEf7oB6aMxsjMnGR0RGiFBkYvQY9VrhXgoOWcmNPaAB/EnFM8
 1d67YDsKTTiuUrb5cYsJZP+HOq0OGw1N3PQgltr/hfn3kS2AMNFvBR/+TyqqJPmuGTPZe5g2EIq
 zvC3UQux5wEozKpegUn1WUHAtmSBqq44q8YiAJVHU73gmN+BGk/j9zaphOpBkcBXuUAtK3kIsQS
 c/dGVilpwT3w7yg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This code was tested for two years within the downstream Snapdragon 845 tree.
It is now perfectly integrated with feedbackd in the Phosh environment.

Changes in v6:
- Rebased again next-20250731, otherwise just a resent.
- Link to v5: https://lore.kernel.org/r/20250419-op6-tri-state-v5-0-443127078517@ixit.cz

Changes in v5:
- Dropped merged
  "Input: gpio-keys - add support for linux,input-value DTS property"
- Link to v4: https://lore.kernel.org/all/cover.1677022414.git.soyer@irl.hu/

Changes in v4:
- DTS: use default debounce-interval, order alphabetically
- Link to v3: https://lore.kernel.org/lkml/cover.1676850819.git.soyer@irl.hu/

Changes in v3:
- rename tri-state-key to alert-slider, fix DTS warnings,

Changes in v2:
- rebase to qcom/for-next
add SND_PROFILE_* identifiers to input-event-codes.h

base-commit: 02ac8d2a011b630481d959298a1cc76ca0717f3e
---
Gergo Koteles (2):
      Input: add ABS_SND_PROFILE
      arm64: dts: qcom: sdm845-oneplus: Add alert-slider

 Documentation/input/event-codes.rst                |  6 ++++
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 39 ++++++++++++++++++++--
 drivers/hid/hid-debug.c                            |  1 +
 include/uapi/linux/input-event-codes.h             |  9 +++++
 4 files changed, 53 insertions(+), 2 deletions(-)
---
base-commit: 84b92a499e7eca54ba1df6f6c6e01766025943f1
change-id: 20250419-op6-tri-state-ed1a05a11125

Best regards,
-- 
David Heidelberg <david@ixit.cz>

