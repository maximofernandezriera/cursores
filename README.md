# Cursores en PL/pgSQL

Una vez revisada la documentación (https://www.postgresqltutorial.com/postgresql-plpgsql/plpgsql-cursor/) podemos aboradar algunos ejercicios más complejos:

NOTA: El esquema de base de datos a utilizar se encuentra en un script sql en este mismo repositorio con el nombre: tablas_hr.sql. Tomado de https://www.sqltutorial.org/sql-sample-database/ tened también encuenta que necesitamos la varaible de entorno autocommit a off tal que así: \set autocommit off

1. Implementar un programa que tenga un cursor que vaya visualizando los salarios de los empleados. Si en el cursor aparece el jefe (Steven King) se debe generar un RAISE EXCEPTION indicando que el sueldo del jefe no se puede ver.

2. Implementar un programa  que averigüe cuales son los JEFES (MANAGER_ID) de cada departamento. En la tabla DEPARTMENTS figura el MANAGER_ID de cada departamento, que a su vez es también un empleado. Hacemos un bloque con dos cursores. Esto se puede hacer fácilmente con una sola SELECT pero vamos a hacerlo de esta manera para probar parámetros en cursores. 

* El primero de todos los empleados
* El segundo de departamentos, buscando el MANAGER_ID con el parámetro que se le pasa.
* Por cada fila del primero, abrimos el segundo cursor pasando el EMPLOYEE_ID
* Si el empleado es MANAGER_ID en algún departamento debemos pintar el Nombre del departamento y el nombre del MANAGER_ID diciendo que es el jefe.
* Si el empleado no es MANAGER de ningún departamento debemos poner “No es jefe de nada”

## NO MIRÉIS LAS SOLUCIONES

# SOLUCIÓN DEL 1

Esta es una posible solución sin encapsular el código en un procedimiento.

      DECLARE
      C1 CURSOR FOR SELECT first_name, last_name, salary FROM EMPLOYEES;
      i RECORD;
      BEGIN
      FOR i IN C1 LOOP
      IF i.first_name = 'Steven' AND i.last_name = 'King' THEN
      RAISE EXCEPTION 'El salario del jefe no puede ser visto';
      ELSE
      RAISE NOTICE '%: % DLS', i.first_name || ' ' || i.last_name, i.salary;
      END IF;
      END LOOP;
      END;

Esta es una solución en un procedimiento. Comenzamos declarando un cursor y definiendo una variable de registro para almacenar los valores del cursor. Luego, el procedimiento ejecuta un bucle FOR que recorre todas las filas del cursor y muestra el nombre y el salario de cada empleado. Si el nombre es "Steven King", se lanza una excepción. Finalmente, el procedimiento se puede llamar posteriormente utilizando la sintaxis "CALL mostrar_salarios();".

      create or replace function mostrar_salarios()
          language plpgsql
      as $$
      declare
          C1 CURSOR FOR SELECT first_name, last_name, salary FROM employees;
          i RECORD;
      begin
          FOR i IN C1 LOOP
                  IF i.first_name = 'Steven' AND i.last_name = 'King' THEN
                      RAISE EXCEPTION 'El salario del jefe no puede ser visto';
                  ELSE
                      RAISE NOTICE '%: % DLS', i.first_name || ' ' || i.last_name, i.salary;
                  END IF;
              END LOOP;
      end;$$


# SOLUCIÓN DEL 2

      CREATE OR REPLACE FUNCTION mostrar_jefes() RETURNS VOID AS
      EMPLEADO employees%ROWTYPE;
      DEPARTAMENTO departments%ROWTYPE;
      jefe departments.manager_id%TYPE;
      C1 CURSOR FOR SELECT * FROM employees;
      C2 CURSOR (j departments.manager_id%TYPE) FOR SELECT * FROM departments WHERE manager_id=j;
      BEGIN
      FOR EMPLEADO IN C1 LOOP
      OPEN C2(EMPLEADO.employee_id);
      FETCH C2 INTO DEPARTAMENTO;
      IF NOT FOUND THEN
      RAISE NOTICE '% No es JEFE de NADA', EMPLEADO.first_name;
      ELSE
      RAISE NOTICE '% ES JEFE DEL DEPARTAMENTO %', EMPLEADO.first_name, DEPARTAMENTO.department_name;
      END IF;
      CLOSE C2;
      END LOOP;
      END;


Esta es la solución en una función. Primero, se declaran las variables para almacenar la información de los empleados, los departamentos y los identificadores de los jefes de departamento. Luego, se definen dos cursores: "C1" para recorrer la tabla "employees" y "C2" para recorrer la tabla "departments" utilizando el identificador del jefe de departamento.

Dentro del bucle "FOR EMPLEADO IN C1 LOOP", se abre el cursor "C2" utilizando el identificador del jefe de departamento del empleado actual, se recupera la información del departamento correspondiente y se verifica si el cursor devolvió algún registro utilizando "NOT FOUND". Si el cursor no devuelve registros, significa que el empleado no es jefe de ningún departamento, por lo que se utiliza "RAISE NOTICE" para mostrar un mensaje indicando que el empleado no es jefe de nada. Si el cursor devuelve registros, significa que el empleado es jefe de al menos un departamento, por lo que se utiliza "RAISE NOTICE" para mostrar un mensaje indicando el nombre del departamento.

Finalmente, se cierra el cursor "C2" y se continúa con el siguiente empleado hasta que se recorren todos los registros de la tabla "employees".
