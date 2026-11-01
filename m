From: Younes Akhouayri <git@younes.io>
Subject: [PATCH v2 0/2] rust: str: parse_int: match kstrtol() sign and
 newline handling
Date: Sun, 01 Nov 2026 16:47:24 +0100
Message-Id: <20261101-b4-parse-int-sign-v2-0-0fd827f52070@younes.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NOw6DMBBEr4K2zkb4Iz6pco+IAsgaNoUdeQEFI
 e4eQ/qUbzTzZgOhyCRwyzaItLBw8An0JYN+bP1AyM/EoHNdqFyX2Fl8t1FS7icUHjyagqq6dr1
 11kDavSM5/pzOR/NjmbsX9dMhOhojyxTiep4u6uj98y8KcyydqQqjqtZ25X0Nsye5coBm3/cvF
 QKHmcQAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793548044; l=2170;
 i=git@younes.io; s=20261027; h=from:subject:message-id;
 bh=ys/TnaZbk7H1Cr9SJ1S3UJJkeWMCmYGXLwebus8t+JM=;
 b=06K7h/lziGWLWlVqPdov9yIDteIVKR08TBcJ93dS4TKJNnxWzJTR0W67Bj964inP/TM3ayYSO
 XF0rfNt05AdAXOcEMRjXNhAzBebY9B+MEY2ZczoSdGHlFzYLgnt1PYT
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=TavwxGPDBjl4XGNQyFLKEW7PKSY4qOWusc7yf6hjV0c=
X-Endpoint-Received: by B4 Relay for git@younes.io/20261027 with auth_id=1332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The documentation of `ParseInt` says that any string parsed by
`kstrtol()` or `kstrtoul()` is also parsed by `from_str()`. That does
not hold today, and `from_str()` also accepts strings that `kstrtol()`
rejects:

    input     kstrtol()     i32::from_str()
    "0x-5"    -EINVAL       Ok(-5)
    "0x+5"    -EINVAL       Ok(5)
    "-+5"     -EINVAL       Ok(-5)
    "+0x5"    5             Err(EINVAL)
    "5\n"     5             Err(EINVAL)

Patch 1 accepts a sign only before the radix prefix. Patch 2 accepts a
single trailing newline, as `kstrtol()` does. The `0o` and `0b`
prefixes are Rust extensions and are left as they are.

Nothing in-tree depends on the old behaviour except the `rust_minimal`
sample, so this is meant for rust-next. The `Fixes:` tags record where
the behaviour comes from; I am not asking for a stable backport.

Tested on UML with the Rust KUnit suite, plus a temporary KUnit test
(not part of this series) that compares `i32::from_str()` with
`kstrtoint()`, a thin wrapper around `kstrtoll()`, on 13 inputs; all of
them agree. Also booted the `rust_minimal` sample: `test_parameter=0x-5`
is now rejected and `test_parameter=+0x5` gives 5.

Signed-off-by: Younes Akhouayri <git@younes.io>
---
Changes in v2:
- Add a doctest for "-0x+5" to patch 1 (Miguel).
- Refer to kstrtol() instead of kstrtoint() in the commit messages and
  the cover letter (Miguel).
- Say in the strip_radix() doc comment which from_str_radix() is meant
  and why a sign is rejected there (Miguel).
- Note the rust-next target and that no stable backport is requested.
- Link to v1: https://patch.msgid.link/20261027-b4-parse-int-sign-v1-0-7f386318a4b7@younes.io

---
Younes Akhouayri (2):
      rust: str: parse_int: only accept a sign before the radix prefix
      rust: str: parse_int: accept a trailing newline like kstrtol()

 rust/kernel/str/parse_int.rs | 36 ++++++++++++++++++++++++++++--------
 1 file changed, 28 insertions(+), 8 deletions(-)
---
base-commit: 7d109178cd644268326cd31702ed46c7ac8bb300
change-id: 20261027-b4-parse-int-sign-36e899fc4f43

Best regards,
--  
Younes Akhouayri <git@younes.io>

