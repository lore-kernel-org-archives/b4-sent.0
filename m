From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Thu, 19 Nov 2026 09:22:04 -0300
Subject: [PATCH] docs: pt_BR: submitting-patches: update LKML role as last
 resort
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261119-pt-br-submitting-patches-lkml-v1-1-1c7170de926f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAyA4VchPdvE1cQMX8V4gFGgCnNZiyEhv
 DtTj9/h/zdQzsIKt2qDzB9ReccCd6ogjE0cGKUrBjrT1TlXYzJsM+rSzmImccDUWBhZcXrNE3p
 /IU81c98RlEfK3Mv6+98ff5f0ycG+U9j3A1y+ZzyBAAAA
X-Change-ID: 20261119-pt-br-submitting-patches-lkml-8832829eefd2
To: Jonathan Corbet <corbet@lwn.net>
Cc: Randy Dunlap <rdunlap@infradead.org>, 
 Eduardo Pereira Cruz <dreduardocruz@gmail.com>, 
 Daniel Pereira <danielmaraboo@gmail.com>, 
 Shuah Khan <skhan@linuxfoundation.org>, linux-doc@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795090927; l=3887;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=GcKCZ7A9qSK4VpwFufllbUosGCXBesddh9epOSyJAXo=;
 b=bFL+aH959aRdVBG+RhE2Vj24tH3JmNAvAUCteRUYQxSzjmJ1eOVbGTQxxBC1xKLWzXmk4FCOY
 6//oC7TjuBHBC0AbGVbCKVn/p6mWofmuXJpSTNOgTih7dnem75x6+FP
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the Brazilian Portuguese translation of submitting-patches.rst to reflect commit 3a198413bb71 ("docs: submitting-patches: make LKML a list of last resort again"), advising contributors to send patches to a subsystem-specific mailing list first and use linux-kernel@vger.kernel.org only as a list of last resort.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Cc: Daniel Pereira <danielmaraboo@gmail.com>
Cc: Jonathan Corbet <corbet@lwn.net>
Cc: Shuah Khan <skhan@linuxfoundation.org>
Cc: Randy Dunlap <rdunlap@infradead.org>
Cc: linux-doc@vger.kernel.org
---
 .../translations/pt_BR/process/submitting-patches.rst | 19 +++++++++++--------
 1 file changed, 11 insertions(+), 8 deletions(-)

diff --git a/Documentation/translations/pt_BR/process/submitting-patches.rst b/Documentation/translations/pt_BR/process/submitting-patches.rst
index 4d1e75935745..3b77363ded18 100644
--- a/Documentation/translations/pt_BR/process/submitting-patches.rst
+++ b/Documentation/translations/pt_BR/process/submitting-patches.rst
@@ -118,10 +118,10 @@ mudar daqui a cinco anos.
 
 Se discussões relacionadas ou qualquer outra informação de contexto por trás da mudança
 puderem ser encontradas na web, adicione tags 'Link:' apontando para isso. Se o patch é o
-resultado de algumas discussões anteriores na lista de e-mails ou algo documentado na
+resultado de algumas discussões anteriores na lista de discussão ou algo documentado na
 web, aponte para ele.
 
-Ao criar links para arquivos de listas de e-mails, de preferência use o serviço
+Ao criar links para arquivos de listas de discussão, de preferência use o serviço
 de arquivo de mensagens lore.kernel.org. Para criar a URL do link, use o
 conteúdo do cabeçalho ``Message-ID`` da mensagem, sem os colchetes angulares
 circundantes. Por exemplo::
@@ -132,11 +132,11 @@ Por favor, verifique o link para se certificar de que ele está realmente
 funcionando e aponta para a mensagem relevante.
 
 No entanto, tente tornar a sua explicação compreensível sem recursos
-externos. Além de fornecer um URL para um arquivo da lista de e-mails ou bug,
+externos. Além de fornecer um URL para um arquivo da lista de discussão ou bug,
 resuma os pontos relevantes da discussão que levaram ao patch conforme enviado.
 
 Caso o seu patch corrija um bug, use a tag 'Closes:' com um URL que referencie o
-relato nos arquivos da lista de e-mails ou em um rastreador público de bugs. Por exemplo::
+relato nos arquivos da lista de discussão ou em um rastreador público de bugs. Por exemplo::
 
 	Closes: https://example.com/issues/1234
 
@@ -244,10 +244,13 @@ encontrar um mantenedor para o subsistema em que está trabalhando,
 Andrew Morton (akpm@linux-foundation.org) serve como um mantenedor de
 último recurso.
 
-linux-kernel@vger.kernel.org deve ser usado por padrão para todos os
-patches, mas o volume dessa lista fez com que vários desenvolvedores a
-ignorassem. Por favor, não envie spam para listas e pessoas não
-relacionadas.
+Você também deve normalmente escolher pelo menos uma lista de discussão para
+receber uma cópia do seu conjunto de patches. Procure no arquivo MAINTAINERS
+por uma lista específica do subsistema; seu patch provavelmente receberá mais
+atenção lá.
+linux-kernel@vger.kernel.org funciona como uma lista de último recurso para
+patches que não possuem uma lista específica do subsistema. Por favor, não
+envie spam para listas e pessoas não relacionadas.
 
 Muitas listas relacionadas ao kernel estão hospedadas em kernel.org;
 você pode encontrar uma lista delas em https://subspace.kernel.org.

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261119-pt-br-submitting-patches-lkml-8832829eefd2

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>

