From: Peder Bergan <peder.bergan@gmail.com>
Subject: [PATCH v2 0/2] rust: str: tie Formatter to its backing buffer
Date: Tue, 17 Nov 2026 18:57:05 +0100
Message-Id: <20261117-formatter-lifetime-v2-0-e216d86ffb57@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHGV/GoC/32OzQ6CMBCEX4X07BoL8ufJ9zAcCmxhDaVkWwiG8
 O5SvHv8JjNfZhMOmdCJR7QJxoUc2fGA+BKJpldjh0DtwSK+xZmUMgdt2SjvkWEgjZ4Mwr1ISol
 trrRuxTGcGDWtp/RV/djN9RsbH0yhUSuHULMamz5E8+Q8ozLAs/Mw4upDqSfnLX/Oa4sMsr8vF
 gkSyjbXSZEVWZrGz84oGq6NNaLa9/0Lf1AmW+sAAAA=
X-Change-ID: 20261117-formatter-lifetime-48391ed7affd
To: Miguel Ojeda <ojeda@kernel.org>
Cc: Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Georgios Androutsopoulos <georgeandrout13@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794938225; l=966;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=vp/LWvvmAzX34f8vnKcLQw+RL3iAYT/77OcdfbM1kEI=;
 b=eeZ1jr/xE+W8GNpkuqpEhdsS1+fV16E1iXTtLdK1DxWqokbyROdzfm0ed6J6RNc2K9J9Wqzsv
 nUaKFAL90/iCO3/qxvg9eqXLMrTMuf5m3cC3XNqHnc+lG3FdDNsexyh
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split the lifetime fix and its documentation into separate patches as
requested by Gary.

I compiled the fix-only first patch with Clippy and ran the string tests
and kernel doctests under x86_64 QEMU. The final source tree is unchanged
from v1, including the previously tested example.

OpenAI Codex assisted with coding and testing.

---
Changes in v2:
- Split the documentation and example into a second patch, as requested by Gary.
- Link to v1: https://lore.kernel.org/rust-for-linux/20261117-formatter-lifetime-v1-1-9d7f38686552@gmail.com/

---
Peder Bergan (2):
      rust: str: tie Formatter to its backing buffer
      rust: str: add an example for Formatter::new

 rust/kernel/str.rs | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)
---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261117-formatter-lifetime-48391ed7affd

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

