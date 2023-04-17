# Cursores en PL/pgSQL

Una vez revisada la documentación (https://www.postgresqltutorial.com/postgresql-plpgsql/plpgsql-cursor/) podemos aboradar algunos ejercicios más complejos:

NOTA: El esquema de base de datos a utilizar se encuentra en un script sql en este mismo repositorio con el nombre: tablas_hr.sql.

1. Implementar un programa que tenga un cursor que vaya visualizando los salarios de los empleados. Si en el cursor aparece el jefe (Steven King) se debe generar un RAISE EXCEPTION indicando que el sueldo del jefe no se puede ver.

2. Implementar un programa  que averigüe cuales son los JEFES (MANAGER_ID) de cada departamento. En la tabla DEPARTMENTS figura el MANAGER_ID de cada
departamento, que a su vez es también un empleado. Hacemos un bloque con dos cursores. (Esto se puede hacer fácilmente con una sola SELECT pero vamos
a hacerlo de esta manera para probar parámetros en cursores). 

* El primero de todos los empleados
* El segundo de departamentos, buscando el MANAGER_ID con el parámetro que se le pasa.
* Por cada fila del primero, abrimos el segundo cursor pasando el EMPLOYEE_ID
* Si el empleado es MANAGER_ID en algún departamento debemos pintar el Nombre del departamento y el nombre del MANAGER_ID diciendo que es el jefe.
* Si el empleado no es MANAGER de ningún departamento debemos poner “No es jefe de nada”
