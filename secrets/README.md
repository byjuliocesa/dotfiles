Arquivos aqui são cifrados com [age](https://github.com/FiloSottile/age). Nunca coloque um segredo em texto puro nesta pasta.

- `dot secret init`: cria a chave e pede a senha que a protege. Roda uma vez só.
- `dot secret add ~/.ssh/id_ed25519`: cifra o arquivo e registra o destino em `manifest.txt`.
- `dot secret restore`: pede a senha e devolve cada arquivo ao lugar, com permissão `600`.
