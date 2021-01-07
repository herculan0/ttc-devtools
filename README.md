# ttc-devtools

> Ferramentas e códigos relacionados a Infraestrutura para Desenvolvimento e disponibilidade em Produção da aplicação ttc (consulte: [ttc-api](https//github.com/herculan0/ttc-api) e [ttc-frontend](https://github.com/ttc-frontend))

De uma maneira mais holística, a infraestrutura para o *frontend* é provisionada e mantida na AWS por instâncias EC2 que estão configuradas em AutoScalling Groups configurado com Multi AZ. Na frente dessa galera, temos um Application Load Balancer, que se encarrega de balancear a carga de acordo com as requisições, assim as máquinas não ficam sobrecarregadas, e caso fique, o AutoScalling cuida de provisionar mais nós. Essa Infraestrutura está em código com o terraform :)</p>

Já para o *backend*, temos um cluster kubernetes que foi criado via [eksctl]() com [arquivo de configuração](). Nele provisionamos o autoscaller e o external-dns, o primeiro nos fornece uma maneira de escalar automaticamente os nossos nós de maneira automatizada, conforme as requisições aumentem. Implementamos o *backend* através de um deployment, contendo o container da aplicação em si e um sidecar para conexão segura e criptografada com o Cloud SQL via proxy.

Resolvi usar o sidecar pois a conexão via VPN Site to Site da GCP para AWS tem um preço bastante elevado, cobrando aproximadamente U$0,05 por hora por tunél, isso apenas do lado do Google. E o dólar está bem caro :B. dessa maneira, a API consegue fazer consultas no através de uma conexão segura, sem o banco precisar estar exposto para a internet.

Para a utilização do sidecar, criação de uma Service Account conforme a [documentação](https://cloud.google.com/sql/docs/mysql/sql-proxy#create-service-account)

Para mais informações de como utilizar o sidecar:
[cloud-proxy-sql-sidecar](https://github.com/GoogleCloudPlatform/cloudsql-proxy/tree/master/examples/kubernetes)

OBS: A documentação não especifica como se conectar com uma aplicação NodeJS, sendo assim, apenas utilizei a conexão via localhost, e como o sidecar e o container principal compartilham da mesma rede, a conexão privada foi feita com sucesso.

## CICD

#### Backend
*ROADMAP*

### Frontend
Para integração contínua e entrega contínua, construímos uma stack do CodePipeline, com o CodeDeploy e o CodeBuild. Toda vez que a branch do repositório do *frontend* main recebe uma alteração, é disparado um trigger que executa a Pipeline, fazendo o build e o deploy.

## Instalação

## EC2, AutoScalling, LoadBalancer...

```sh
cd ttc-ec2-asg-elb
terraform init
terraform apply
```
Passe a chave SSH(keypair) para acesso ao servidores.


## Cluster EKS
```sh
eksctl create cluster \                          
  --name dev \                           
  --node-type t2.micro \                
  --nodes 3 \                  
  --nodes-min 2 \     
  --nodes-max 4 \
  --region us-east-1 \
  --managed --spot --asg-access \
  --zones=us-east-1a,us-east-1b,us-east-1d
```

Desse maneira, o Cluster é criado e o autoscalling group é configurado nas zonas passadas por parâmetro, com os nós do tipo t2.micro. 

### Ativar iamserviceaccount

Para as próximas funcionalidades, é necessário associar o iam oidc provider.

```sh
eksctl utils associate-iam-oidc-provider \
    --cluster dev \
    --approve
```

### Auto-Scaler

```sh
kubectl -f k8s/cluster-autoscaler.yaml
```
Consulte a documentação para mais informações: [auto-scaler](https://docs.aws.amazon.com/pt_br/eks/latest/userguide/cluster-autoscaler.html)

### External-DNS

Deve-se criar uma policy e adicionar à IAM do pod executando o external-dns, dessa maneira, conseguimos fazer com que o external-dns manuseie os Registros, tais como A e TXT de determinada HostedZone.

Para o uso do external-dns, basta utilizar a seguinte annotation:

`external-dns.alpha.kubernetes.io/hostname: api.herculano.xyz`

Ao criar a policy, lembre-se de guardar o ARN gerado para utilizar no  adicionar as informações no yaml do external-dns.
```sh
aws iam create-policy \    
    --policy-name AWSExternalDNSIAMPolicy \
    --policy-document file://iam-policy-route53.json

eksctl create iamserviceaccount \
    --name external-dns \
    --namespace default --cluster dev \
    --attach-policy-arn arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AWSExternalDNSIAMPolicy \
    --approve
```
Altere o yaml de acordo, configurando a HostedZone e HostedZoneID.

```sh
kubectl -f k8s/external-dns.yaml

```

Consulte a documentação para mais informações: [external-dns](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md)

Uma limitação que encontrei nesse caso, foi não ter conseguido fazer uma regra com base no caminho, mas sim criar um subdomínio para o *backend* com a annotation no Service da aplicação: 

Um carinha que tem essa funcionalidade é o [AWS LoadBalancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/), tentei implantar, porém, sem sucesso :(, mas vai entrar no ROADMAP com certeza!!!


## Release History

* 0.0.1
    * Work in progress

## Roadmap

- [x] Stack de Infraestrutura para EC2 Autoscalling, LoadBalancer, MultiAZ via terraform
- [x] Criação do cluster
- [x] Addons no Cluster(auto-scaler e external-dns)
- [x] Implantação do CICD do Frontend (CodePipeline)
- [ ] Criar Apontamento DNS para o Banco de Dados
- [ ] Implantar CICD Backend (JenkinsX? Tekton?)
- [ ] Implantatação AWS LoadBalancer Controller
- [ ] Migrar cluster eks para terraform
- [ ] Melhorar a documentação
... whats next?

## Meta

Lucas Herculano – [@linkedin](https://linkedin.com/in/lucasgherculano) – lucasgherculano@gmail.com

## Contributing

1. Forque o projeto (<https://github.com/herculan0/ttc-app/fork>)
2. Crie o seu feature branch (`git checkout -b feature/fooBar`)
3. Commit as alterações(`git commit -am 'Add some fooBar'`)
4. Faça o Push (`git push origin feature/fooBar`)
5. Crie uma Pull Request
