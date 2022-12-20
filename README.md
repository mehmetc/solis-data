# SOLIS Data-API


De [API](https://en.wikipedia.org/wiki/API) is een op het [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) principe gebaseerde API die de [JSON:API](https://jsonapi.org/) standaard volgt. [JSON:API](https://jsonapi.org/) focust zich op de eenvoud van implementatie zowel in de frontend als de backend.
Dit document bevat geen uitgebreide lijst van entiteiten of api endpoints. [JSON:API](https://jsonapi.org/) maakt gebruik van een schema alle entiteiten kunnen op dezelfde wijze opgevraagd, aangemaakt, verwijderd en aangepast worden. Het schema kan via de
Schema Endpoint opgevraagd worden.


## Model
De Data-API wordt opgebouwd aan de hand van een SHACL file. De SHACL file kan opgebouwd worden door een Google Sheet template.
Zie de SOLIS gem voor meer informatie.

## Authenticatie

We maken gebruik van [OAuth2](https://oauth.net/2/). Om de API te bevragen heb je een token of een login nodig.


## Audit

Alle queries naar de API komen in een audit log terecht deze kan door beheerders bevraagd worden.


## Identifiers

Bij het aanmaken van een record wordt er een [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) (v4:random) aangemaakt voor de nieuwe entiteit. Als er een [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) aanwezig is wordt deze gebruikt bij het aanmaak van nieuwe entiteiten. We raden aan om het systeem een [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) te laten genereren.


## Endpoints

### Basis

```
Content-Type: application/vnd.api+json
```


Oproepen van de basis endpoint geeft een lijst van entiteiten die kunnen gebruikt worden om data op te vragen. Er bestaan 2 soorten entiteiten.



* Abstracte entiteiten: deze kunnen vergeleken worden met een super class. Kunnen gebruikt worden om te queryen bv. De entiteit Persoon is de super class voor archivaris, inbinder, vrijwilliger, … Als men alle personen opvraagt krijg je een lijst van personen met type archivaris, inbinder, vrijwilliger.
* Data entiteiten: deze kan men gebruiken om 1 of meerdere entiteiten van een bepaald type te lezen, schrijven, aanpassen en te verwijderen. Kortom alle [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) operaties.


```
curl https://data.example.com/
Content-Type: application/json
[
    "/aangroei",
    "/adressen",
    "/agenten",
    "/archieven",
...
    "/bronverwijzingen",
    "/concepten",
    "/contact_personen",
...
    "/talen",
    "/titels",
    "/toegangen",
    "/verwervingen",
    "/waarderingen"
]
```



### Schema

[https://data.example.com//schema.json](https://data.example.com//schema.json)


```
Content-Type: application/json
```


Deze endpoint roept een schema op en kan gebruikt worden door [JSON:API](https://jsonapi.org/) bibliotheken voor het opbouwen van een interne api. Zoals [spraypaint](https://github.com/graphiti-api/spraypaint.js) kijk op deze [lijst](https://jsonapi.org/implementations/#client-libraries) voor een uitgebreidere lijst.

Het schema kan opgevraagd worden in verschillende formaten. Deze formaten kunnen door een ondersteunde [mime-type](https://en.wikipedia.org/wiki/Media_type) in een [Accept header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) op te geven of een query parameter.


<table>
  <tr>
   <td><strong>Accept header/query param mime-type</strong>
   </td>
   <td><strong>Omschrijving</strong>
   </td>
  </tr>
  <tr>
   <td>application/plantuml
   </td>
   <td>Schema als een <a href="https://plantuml.com/">PlantUML</a> file
   </td>
  </tr>
  <tr>
   <td>application/n-triples
   </td>
   <td>Schema als n-triples
   </td>
  </tr>
  <tr>
   <td>application/n-quads
   </td>
   <td>Schema als n-quads
   </td>
  </tr>
  <tr>
   <td>application/ld+json
   </td>
   <td>Schema als JSON-LD 
   </td>
  </tr>
  <tr>
   <td>application/rdf+json
   </td>
   <td>Schema als RDF/JSON
   </td>
  </tr>
  <tr>
   <td>text/html
   </td>
   <td>Schema als HTML
   </td>
  </tr>
  <tr>
   <td>text/n3
   </td>
   <td>Schema als n3 notatie
   </td>
  </tr>
  <tr>
   <td>text/turtle
   </td>
   <td>Schema as Turtle. (Preferred format)
   </td>
  </tr>
</table>


Bv.

Via een [Accept header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept)

HEADER Accept: text/turtle

[https://data.example.com//schema.json](https://data.example.com//schema.json)

Of via een accept parameter

[https://data.example.com//schema.json?accept=text/turtle](https://data.example.com//schema.json?accept=text/turtle)


### Entity

[https://data.example.com/[ENTITY](https://data.example.com/[ENTITY)]

[https://data.example.com/[ENTITY]/[ID](https://data.example.com/[ENTITY]/[ID)]


```
Content-Type: application/vnd.api+json
```


Opvragen van data voor een entity kan gebeuren door gebruik te maken van de JSON:API query mogelijkheden als ook op een RESTful manier door de id van de entiteit.


### Model

[https://data.example.com/[ENTITY]/model](https://data.example.com/[ENTITY]/model)


```
Content-Type: application/json
```


Ophalen van een entity beschrijving. Geeft een blauwdruk van de attributen die nodig zijn om een entiteit aan te maken.

Bv.

[http://data.example.com/bronverwijzingen/model](http://data.example.com/bronverwijzingen/model)


```
Content-Type: application/json
```


{

    "type": "bronverwijzingen",

    "attributes": {

        "record": {

            "description": "",

            "mandatory": true,

            "data_type": "string"

        },

        "archief": {

            "description": "",

            "mandatory": true,

            "data_type": "string"

        }

    }

}


### Vandal

[https://data.example.com/vandal](https://data.example.com/vandal)

UI om [JSON:API](https://jsonapi.org/) te testen alsook queries te schrijven.


## Queries

Lees de JSON:API [specificaties](https://jsonapi.org/format/) voor een uitgebreide uitleg van hoe queries opgebouwd worden hieronder geven we een paar voorbeelden.


### CREATE

POST [https://data.example.com/bronverwijzingen](https://data.example.com/bronverwijzingen)

HEADER `Content-Type: application/json`

BODY


```
{
   "type": "bronverwijzingen",
   "attributes": {
       "record": "Test record",
       "archief": "Persoonlijk archief van Test"
   }
}
```



### READ

Bv.


#### Alle archieven

GET [https://data.example.com/archieven](https://data.example.com/archieven)


#### Archief met id=1

GET [https://data.example.com/archieven/1](https://data.example.com/archieven/1)

GET [https://data.example.com/bronverwijzingen?filter[id][eq]=1&page[number]=1&page[size]=10](https://data.example.com/bronverwijzingen?filter[id][eq]=1&page[number]=1&page[size]=10)

GET [https://data.example.com/archieven?filter[beheerder.id][eq]=1&sort=beheerder.id&include=beheerder.rol](https://data.example.com/archieven?filter[beheerder.id][eq]=1&sort=beheerder.id&include=beheerder.rol)


### UPDATE

PUT [https://data.example.com/bronverwijzingen/1](https://data.example.com/bronverwijzingen/1)


```
{
   "type": "bronverwijzingen",
   "attributes": {
       "id": "1",
       "record": "Test record",
       "archief": "Persoonlijk archief van Test"
   }
}
```



### DELETE

DELETE  [https://data.example.com/archieven/1](https://data.example.com/archieven/1)