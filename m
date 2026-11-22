From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 11:34:00 -0300
Subject: [PATCH] docs/translations/pt_BR: process: add
 programming-language.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-programming-language-pt-br-v1-1-a48a23d365ee@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAyA4VeRnBdYw/SwVxk7tDZ2GbOWVGUgv
 rtxO37w829QWYUr3JsNlFepMmWDuzTQv3xOjBLNQFfqnCPColNSP46SE34sWLw1ZcagOHiK5EN
 sb10LNijKg3x/88fz77qEN/fzeYR9PwCAU92PfgAAAA==
X-Change-ID: 20261122-programming-language-pt-br-fa2d2abd5465
To: linux-doc@vger.kernel.org
Cc: skhan@linuxfoundation.org, corbet@lwn.net, danielmaraboo@gmail.com, 
 rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795358039; l=4721;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=6WWYvKMSz1hBySp2gMR28ODo3vXl8sMA6fas4axl2Do=;
 b=3YYkUCci88Krd9Fa+NIWK3IpM6za2OowvhhfIIXOyUDz0oixJOcXC8BlfyJ3CeEJGzDc0JbTF
 Fxw1QS0sP6yBn05pN+Jtg1R4DxkWJ6WWa7wZ/m/30CXigm1wjayTJkx
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Brazilian Portuguese translation of
Documentation/process/programming-language.rst, which documents the C
dialect used by the kernel and the attributes conventions, plus the Rust
support under CONFIG_RUST.

All eleven footnote definitions and their URLs are kept verbatim, as they
are what makes the references resolve.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 Documentation/translations/pt_BR/process/index.rst |  1 +
 .../pt_BR/process/programming-language.rst         | 62 ++++++++++++++++++++++
 2 files changed, 63 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/index.rst b/Documentation/translations/pt_BR/process/index.rst
index d072f7e46767..4a6037182473 100644
--- a/Documentation/translations/pt_BR/process/index.rst
+++ b/Documentation/translations/pt_BR/process/index.rst
@@ -46,6 +46,7 @@ devem estar familiarizados.
    Adicionando uma nova chamada de Sistema <adding-syscalls>
    Por que a classe de tipo "volatile" não deve ser usada <volatile-considered-harmful>
    Como não Deixar as ioctls malfeitas <botching-up-ioctls>
+   Linguagem de programação <programming-language>
 
 Guias de políticas e declarações de desenvolvedores
 ---------------------------------------------------
diff --git a/Documentation/translations/pt_BR/process/programming-language.rst b/Documentation/translations/pt_BR/process/programming-language.rst
new file mode 100644
index 000000000000..4a909ef577e9
--- /dev/null
+++ b/Documentation/translations/pt_BR/process/programming-language.rst
@@ -0,0 +1,62 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+.. _programming_language:
+
+Linguagem de programação
+========================
+
+O kernel Linux é escrito na linguagem de programação C [c-language]_. Mais
+precisamente, ele é tipicamente compilado com ``gcc`` [gcc]_ sob
+``-std=gnu11`` [gcc-c-dialect-options]_: o dialeto GNU do ISO C11.
+``clang`` [clang]_ também é suportado; veja a documentação em
+:ref:`Building Linux with Clang/LLVM <kbuild_llvm>`.
+
+Esse dialeto contém muitas extensões à linguagem [gnu-extensions]_, e muitas
+delas são usadas dentro do kernel como algo corriqueiro.
+
+Atributos
+----------
+
+Uma das extensões comuns usadas em todo o kernel são os atributos
+[gcc-attribute-syntax]_. Atributos permitem introduzir semântica definida
+pela implementação a entidades da linguagem (como variáveis, funções ou
+tipos) sem precisar fazer mudanças sintáticas significativas na linguagem
+(por exemplo, adicionar uma nova palavra-chave) [n2049]_.
+
+Em alguns casos, os atributos são opcionais (ou seja, um compilador que não
+os suporte ainda deve produzir código adequado, mesmo que seja mais lento ou
+que não faça tantas verificações e diagnósticos em tempo de compilação).
+
+O kernel define pseudopalavras-chave (por exemplo, ``__pure``) em vez de usar
+diretamente a sintaxe de atributos do GNU (por exemplo,
+``__attribute__((__pure__))``) para detectar quais podem ser usados e/ou para
+encurtar o código.
+
+Consulte ``include/linux/compiler_attributes.h`` para mais informações.
+
+Rust
+----
+
+O kernel tem suporte à linguagem de programação Rust [rust-language]_ sob
+``CONFIG_RUST``. O código Rust é compilado com ``rustc`` [rustc]_ sob
+``--edition=2021`` [rust-editions]_. Edições são uma forma de introduzir
+pequenas mudanças na linguagem que não são compatíveis com versões
+anteriores.
+
+Além disso, alguns recursos instáveis [rust-unstable-features]_ são usados no
+kernel. Recursos instáveis podem mudar no futuro, portanto é uma meta
+importante chegar a um ponto em que apenas recursos estáveis sejam usados.
+
+Consulte Documentation/rust/index.rst para mais informações.
+
+.. [c-language] http://www.open-std.org/jtc1/sc22/wg14/www/standards
+.. [gcc] https://gcc.gnu.org
+.. [clang] https://clang.llvm.org
+.. [gcc-c-dialect-options] https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html
+.. [gnu-extensions] https://gcc.gnu.org/onlinedocs/gcc/C-Extensions.html
+.. [gcc-attribute-syntax] https://gcc.gnu.org/onlinedocs/gcc/Attribute-Syntax.html
+.. [n2049] http://www.open-std.org/jtc1/sc22/wg14/www/docs/n2049.pdf
+.. [rust-language] https://www.rust-lang.org
+.. [rustc] https://doc.rust-lang.org/rustc/
+.. [rust-editions] https://doc.rust-lang.org/edition-guide/editions/
+.. [rust-unstable-features] https://github.com/Rust-for-Linux/linux/issues/2

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-programming-language-pt-br-fa2d2abd5465

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>

