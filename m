From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:02:50 +0800
Subject: [PATCH v6.6 1/4] file: add fd_raw cleanup class
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-6-6-y-v1-1-8731db3f4834@gmail.com>
References: <20240918-statx-stable-linux-6-6-y-v1-0-8731db3f4834@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-6-6-y-v1-0-8731db3f4834@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>, stable@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=931;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=nh/hkFaW6sBtnLKjsDul7wXSyoueegBRVpblnjc9WjE=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t2MHMIJ5PmTSuk1NLOFRlkRruwsqG5O8fL00
 +YDMjuOEemJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurdjAAKCRCwMePKe/7Z
 bu3gD/wJ2uPhlSMSgJw3MNZm0VeGU3KfSqpxOsfnuIRZa7FPMDeZPez4VMGKXn99cM2PNzEujmt
 pMrvoDwg64javlJ3woiM7zhgXFJFvse6LaXOJFFarTCNDhYY+KFVXCWXBWbe/CVM+o1xaTiD9U9
 A26Hvz2JrvHz9kvXRZee44ipG+LNuPj1rffAMurtAWnZIj/WayxDgAxkHdeKYlgMsDcFRWjXHLr
 fMQtWJP8wToDttduyNXs9Nu2Jnvd7vr81Ry1hUCmS8UdYrBupj8XAfGbCm5jH2Id4jyD5oM8Bw/
 MlRCJRvxYpdUF48qvALEGLzsOcjJHqG5fPhc+G3VskK4fycGO46uVA1e7MaWOooubsLyUQnxRme
 +p8F0EFu80gc7R9NV3/OoEW7eBFpjc3UG8lDHD2lq+iVpg1yG38ajnziKN/lNxM+ED1tMa6uFaN
 da4bl/RHggZjcw56Xnk/O6wEkp2PS7Ibp/D66y0yePIwQeQxc7ze9Q0KO2fi0vlBt08Z5QM+Min
 2DLJh0ncHJS9eXBAQ0or+QRDeJ+PpsfSOQ92pfFoYSoz1QTG33CCj5oQB0D4O6WnTK+PcLJRVD1
 hPrHpE4dOyKZqXehLPWUWbv6UPE8KSxu/O8WwGThfmXAURsUF+psqia3pQol2T3XQ+ar5TI0xoA
 /k+nwCgtq+SFjDA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christian Brauner <brauner@kernel.org>

commit a0fde7e upstream.

So we can also use CLASS(fd_raw, f)(fd) for codepaths where we allow
FMODE_PATH aka O_PATH file descriptors to be used.

Signed-off-by: Christian Brauner <brauner@kernel.org>

Cc: <stable@vger.kernel.org> # 6.6.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 include/linux/file.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/file.h b/include/linux/file.h
index 6e9099d29343..963df2dc4f61 100644
--- a/include/linux/file.h
+++ b/include/linux/file.h
@@ -82,6 +82,7 @@ static inline void fdput_pos(struct fd f)
 }
 
 DEFINE_CLASS(fd, struct fd, fdput(_T), fdget(fd), int fd)
+DEFINE_CLASS(fd_raw, struct fd, fdput(_T), fdget_raw(fd), int fd)
 
 extern int f_dupfd(unsigned int from, struct file *file, unsigned flags);
 extern int replace_fd(unsigned fd, struct file *file, unsigned flags);

-- 
2.43.0

