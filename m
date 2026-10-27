From: Younes Akhouayri <git@younes.io>
Subject: [PATCH 0/2] rust: str: parse_int: match kstrtol() sign and newline
 handling
Date: Tue, 27 Oct 2026 13:10:02 +0100
Message-Id: <20261027-b4-parse-int-sign-v1-0-7f386318a4b7@younes.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWZuEatxeRSyoKWNR0kEk4t0Vy
 +8k579AyDMJ1NEFng4WXlxAGkdgps6NhDwEg0pUniaqwF7j2nkJu9tQeHSY5VRWlTXa6gzCb/V
 k+fyaTftb9n4ms70huO8H0BnwUXUAAAA=
X-Change-ID: 20261027-b4-parse-int-sign-36e899fc4f43
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Daniel Gomez <da.gomez@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793103002; l=1463;
 i=git@younes.io; s=20261027; h=from:subject:message-id;
 bh=zTt8DAHZuMHakgutZ0swbdOulHE2DnMp45ikzS7giQQ=;
 b=O0yOTqyIwfn1XZyXWmC1vlbvSbtpaVkcyFqc37vTG2uQ8ocxhZBOzF+G1Hi+yvNd+CVPuitZR
 KSOBAGipiB1C1O3AneAeEB4OegJ6XnCs81SLFSJTArXuDyoU94lDe7f
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=TavwxGPDBjl4XGNQyFLKEW7PKSY4qOWusc7yf6hjV0c=
X-Endpoint-Received: by B4 Relay for git@younes.io/20261027 with auth_id=1332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The documentation of `ParseInt` says that any string parsed by
`kstrtol()` or `kstrtoul()` is also parsed by `from_str()`. That does
not hold today, and `from_str()` also accepts strings that `kstrtol()`
rejects:

    input     kstrtoint()   i32::from_str()
    "0x-5"    -EINVAL       Ok(-5)
    "0x+5"    -EINVAL       Ok(5)
    "-+5"     -EINVAL       Ok(-5)
    "+0x5"    5             Err(EINVAL)
    "5\n"     5             Err(EINVAL)

Patch 1 accepts a sign only before the radix prefix. Patch 2 accepts a
single trailing newline, as `kstrtol()` does. The `0o` and `0b`
prefixes are Rust extensions and are left as they are.

Tested on UML with the Rust KUnit suite, plus a temporary KUnit test
(not part of this series) that compares `i32::from_str()` with
`kstrtoint()` on 12 inputs; all of them now agree. Also booted the
`rust_minimal` sample: `test_parameter=0x-5` is now rejected and
`test_parameter=+0x5` gives 5.

Signed-off-by: Younes Akhouayri <git@younes.io>
---
Younes Akhouayri (2):
      rust: str: parse_int: only accept a sign before the radix prefix
      rust: str: parse_int: accept a trailing newline like kstrtol()

 rust/kernel/str/parse_int.rs | 33 +++++++++++++++++++++++++--------
 1 file changed, 25 insertions(+), 8 deletions(-)
---
base-commit: 7d109178cd644268326cd31702ed46c7ac8bb300
change-id: 20261027-b4-parse-int-sign-36e899fc4f43

Best regards,
--  
Younes Akhouayri <git@younes.io>

