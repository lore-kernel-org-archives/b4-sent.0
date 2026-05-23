From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] Introduce OnePlus 6/6T touchscreen compatible
Date: Sat, 23 May 2026 11:45:33 +0200
Message-Id: <20260523-synaptics-rmi4-dt-v2-0-0645122babdc@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD13EWoC/32NQQ6DIBBFr2Jm3WkQjNqueo/GBcJYZ1E0QIjWc
 PdSD9Dle8l//4BAninAvTrAU+LAiysgLxWYWbsXIdvCIIVsRSN6DLvTa2QT0L+5QRux1zROqu5
 uwhoou9XTxNvZfA6FZw5x8ft5keqf/VdLNQqUVslRG0Ntpx68cbyaDww55y9LC2BXsAAAAA==
X-Change-ID: 20260408-synaptics-rmi4-dt-8aebf31790dc
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=899; i=david@ixit.cz;
 h=from:subject:message-id; bh=0KtWD3IPpWmaEU9h6RkZwg+0yU/vLY50Z8txmH8tMi0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqEXc/xpQXnr5nOblpMjRhgj1pTYITEyEbfR/sr
 iTHshRVgBeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCahF3PwAKCRBgAj/E00kg
 cshrEAChXOxLaXHSe0L0BcsBrcmGr6IueyaxyN9B4gXNJ5nC/Yr+Td+wgqnjF9YNeN7cXVnJDQx
 hMXYy+VVcoqtNNjy1rb3ywS6AczBDAQXembyaOFoHApv907+3NntepIRyuL6sYL41lJHzPmvx0J
 oIEF6omKTE4eqOmcKuMn2WITPrNDwYSS1BY4g4PWz0ldBEc8D8FfhmobVOlWIhnXZs6LzyezimO
 qem4Ue4NDoAAJBtGxWMegRtAQhWVlC88fzHwWNKpQSfnmEwT8qBwZjvTvEVbJqHDcwX/J2QJiYz
 +JBeZKSNCBY7qbt3OpBdeCw+5Ouy1ZZND+TskuXnCxny+EWc5gSwL6lIf3puKW8ARyADm1jpoOc
 IXNdUcyIV1d2Bxx5cNvgkv9wx9VIyIk5VSgI93bYV4ZAE901miY3HBmd0BkzPO1bWXreJw/XiVY
 itT0LbLExJya4iIJiTbf+rOQTYU9ww0YndN7xfXoDBZjcFhod1vzHbt1Rkqy0kFSPCSkFW6q2hX
 Xk6IzFZQaLtkbzFOFM31mFsty77uO5Z8nixrZ/EsVj/LD5e9sdysgxYj20miNzFzvA+pJ6JXaW7
 WYWskth7TjbX10NvN27KNJLItqUWajroB3At7pB7UOtOMO2KhLOtTK5kT7MXTxDmnqUhM9gyy1i
 QkRfKBUs748ZfMQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mostly related to the
  https://codeberg.org/sdm845/linux/commits/branch/b4/synaptics-rmi4
series, but independent on other changes which I trying to upstream for
more than one year.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Add R-b tag.
- Link to v1: https://lore.kernel.org/r/20260408-synaptics-rmi4-dt-v1-0-2d32bacce673@ixit.cz

---
David Heidelberg (2):
      dt-bindings: input: syna,rmi4: Document syna,rmi4-s3706b
      arm64: dts: qcom: sdm845-oneplus: Update compatible to include model

 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 11 ++++++++---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi    |  2 +-
 2 files changed, 9 insertions(+), 4 deletions(-)
---
base-commit: 5200f5f493f79f14bbdc349e402a40dfb32f23c8
change-id: 20260408-synaptics-rmi4-dt-8aebf31790dc

Best regards,
-- 
David Heidelberg <david@ixit.cz>

