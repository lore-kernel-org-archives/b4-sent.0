From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/4] Add framebuffer on Xiaomi Poco F1 and disable the
 MDSS on tianma panel variant
Date: Wed, 01 Apr 2026 22:40:13 +0200
Message-Id: <20260401-beryllium-fb-v3-0-ec7d443402ab@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK2CzWkC/12Oyw6CMBBFf8V0bc20lYKu/A/jgraDTIJgWmxAw
 r9bcOFjeW5yTu7EAnrCwI6biXmMFKhrE6jthtm6bK/IySVmEqQGATk36MemoceNV4Y7hUVurAS
 DwJJy91jRsObOl8Q1hb7z41qPYlnfISXEbygKDnwPRZkV4ITM8EQD9Tv7ZEsmym/170OUSVXa6
 IOrTK7BftR5nl/kWwPv4QAAAA==
X-Change-ID: 20260107-beryllium-fb-d3e87bc20be0
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, Dzmitry Sankouski <dsankouski@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1569; i=david@ixit.cz;
 h=from:subject:message-id; bh=jFxGbwEin6L02eSnQINsc7WtTy3pSmdJ1Ta0GfkUtV4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzYKuY2d9u8/IoyuOwReNEEB5Nlnmx96ewC13O
 MH/r+AiyNeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2CrgAKCRBgAj/E00kg
 ctueD/9/QokHBZ0ePZfGMS4Jhy8sFM5bznYUnG3DazaR3l8nID++qEh3r+ZpfrEqizSByR8Dyoa
 OEmW9fo/KOdnRrw2j6hUgINeoVErKy5DNceIMuj1D2PraDu9KiCgcC7NTIkc3W/ndCnYPLOLkwo
 +lPzb9t6tccJswvBZ1JP3vizKJHkhkjNK5wl5chnewE/reWdw4gy2PzicPknzVhiYhBTF+2WT6L
 vyPPkGwPo/kkkTc4CJLL8JlR6/Vg08J/pMa8D+NNgr2xeIuAT13VSDIDJ9Huf/VOEprgRtLI10/
 V49a6bO1UpioHZIZctyM0LKh8+hmf8MqI/tAOsa1vyUWYt/7PkYYRc3Wito3XHWIGLfdDSr9JNM
 KZXJyBP3cMWCYHviePYkFWm8QejvFBEaEtf6ejOUxr8RBCZy8A3AdvAmgstzUVvGzhRmcGfOUzr
 LGAZlOE5fD9kh91OmlH7weLj3GJTkjsc3YsE4GXRtmT1KapdYvDhvlJQyJ1tw1+XlWuyEJGlHkV
 fc9DmapaDNW/XEZ3T4mP8Oz3Ol/5WzL9M+r0LCidObCnBXlvMsGsfba5W/vcHebyLZpb7irPqrk
 KLcN7/WCzjR3IgkuY9/ZYkmRUBNw8WVMqPVHlPz1BCsxgVgtG3INSUmCS0ixpNaEkUmAFgpwqvO
 Eo9BfpsoQWNqZAg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable framebuffer for early console output.

Due to broken panel driver on tianma and no visual output it's better
to disable the MDSS so the framebuffer stays on. 

In case second patch gets rejected, please apply the first one standalone

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Changes in v3:
- Strip label from framebuffer nodes where unused and remove -0 postfix. (Konrad)
- Link to v2: https://lore.kernel.org/r/20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz

Changes in v2:
- Added few conversion to use memory-region.
- Corrected framebuffer node name. (Konrad)
- Link to v1: https://lore.kernel.org/r/20260311-beryllium-fb-v1-0-408a580d125e@ixit.cz

---
David Heidelberg (3):
      arm64: dts: qcom: sdm845-oneplus: Drop address from framebuffer node
      arm64: dts: qcom: sdm845-shift-axolotl: Convert fb to use memory-region
      arm64: dts: qcom: sdm845-samsung-starqltechn: Convert fb to use memory-region

Petr Hodina (1):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Introduce framebuffer

 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi      |  2 +-
 arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts  |  7 ++++---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts        |  8 ++++----
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi    | 16 ++++++++++++++++
 4 files changed, 25 insertions(+), 8 deletions(-)
---
base-commit: bd0f139e5fc11182777b81cefc3893ea508544ec
change-id: 20260107-beryllium-fb-d3e87bc20be0

Best regards,
-- 
David Heidelberg <david@ixit.cz>

