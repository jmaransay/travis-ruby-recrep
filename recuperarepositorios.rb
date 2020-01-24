require 'travis'
require 'travis/pro'
require 'time'
require 'proc/wait3' # para hacer pausas entre el resultado de mostrar cada repositorio
require 'travis/tools/github' 	# para acceder con el login de github, no lo usamos
require 'highline/import' 		# para ocultar contraseñas

# Recuperamos los argumentos del programa, el primero (cuasi) será el usuario cuyos repositorios comprobaremos

cuasi, rest = ARGV

# Incuimos nuestro token de Travis (ojo, es diferente del de GitHub)

Travis::Pro.access_token = 'YOURTRAVISCITOKENHERE'

# Organización en la que queremos hacer las comprobaciones

organization = 'POO1920'

# Array de pares [nombre práctica, fecha límite de entrega]:

repos_fechas = [
	['practica-01-01-parte-01',      Time.utc(2019, 11, 01, 20, 00, 00)],
        ['practica-01-01-parte-02',      Time.utc(2019, 11, 01, 20, 00, 00)],
	['practica-01-01-parte-03',      Time.utc(2019, 11, 01, 20, 00, 00)],
	['practica-01-02-parte-01',      Time.utc(2019, 11, 01, 20, 00, 00)], 
	['practica-01-02-parte-02',      Time.utc(2019, 11, 01, 20, 00, 00)], 
	['practica-01-02-parte-03',      Time.utc(2019, 11, 01, 20, 00, 00)],
	['practica-01-03-parte-01-c',    Time.utc(2019, 11, 01, 20, 00, 00)], 
	['practica-01-03-parte-02-c',    Time.utc(2019, 11, 01, 20, 00, 00)],
	['practica-01-03-parte-01-java', Time.utc(2019, 11, 01, 20, 00, 00)],
        ['practica-01-03-parte-02-java', Time.utc(2019, 11, 01, 20, 00, 00)],

	['practica-02-01-parte-01-c',    Time.utc(2019, 11, 15, 20, 00, 00)], 
	['practica-02-01-parte-02-c',    Time.utc(2019, 11, 15, 20, 00, 00)],
	['practica-02-01-parte-01-java', Time.utc(2019, 11, 15, 20, 00, 00)],
        ['practica-02-01-parte-02-java', Time.utc(2019, 11, 15, 20, 00, 00)],
	['practica-02-02-parte-01-c',    Time.utc(2019, 11, 15, 20, 00, 00)], 
	['practica-02-02-parte-02-c',    Time.utc(2019, 11, 15, 20, 00, 00)],
	['practica-02-02-parte-01-java', Time.utc(2019, 11, 15, 20, 00, 00)],
        ['practica-02-02-parte-02-java', Time.utc(2019, 11, 15, 20, 00, 00)],

        ['practica-03-01-parte-01-c',    Time.utc(2019, 12, 05, 20, 00, 00)],
        ['practica-03-01-parte-01-java', Time.utc(2019, 12, 05, 20, 00, 00)],
        ['practica-03-02-parte-01-c',    Time.utc(2019, 12, 05, 20, 00, 00)],
        ['practica-03-02-parte-01-java', Time.utc(2019, 12, 05, 20, 00, 00)],
        ['practica-03-02-parte-02-c',    Time.utc(2019, 12, 05, 20, 00, 00)],
        ['practica-03-02-parte-02-java', Time.utc(2019, 12, 05, 20, 00, 00)],
        
	['practica-04-01-parte-01-c',    Time.utc(2019, 12, 20, 20, 00, 00)],
        ['practica-04-01-parte-01-java', Time.utc(2019, 12, 20, 20, 00, 00)],
        ['practica-04-01-parte-02-java', Time.utc(2019, 12, 20, 20, 00, 00)],
        ['practica-04-02-parte-01-c',    Time.utc(2019, 12, 20, 20, 00, 00)],
        ['practica-04-02-parte-01-java', Time.utc(2019, 12, 20, 20, 00, 00)],
        
	['practica-04-03-parte-01-java', Time.utc(2020, 01, 17, 20, 00, 00)],
        ['practica-05-01-parte-01-java', Time.utc(2020, 01, 17, 20, 00, 00)],
        
]

# Nombre del tag que deberían haber generado los estudiantes en sus repositorios:

tagentrega = 'entrega'

# Acceso con credenciales GitHub, funciona también con autenticación en dos pasos

# Set up GitHub tool for doing the login handshake.
# github = Travis::Tools::Github.new(drop_token: true) do |g|
#  g.ask_login    = -> { ask("GitHub login: ") }
#  g.ask_password = -> { ask("Password: ") { |q| q.echo = "*" } }
#  g.ask_otp      = -> { ask("Two-factor token: ") }
# end

# Create temporary GitHub token and use it to authenticate against Travis CI.
# github.with_token do |token|
#  Travis::Pro.github_auth(token)
# end

# Mostramos el usuario con el que nos hemos logado

user = Travis::Pro::User.current
puts "Hola #{user.name}!"

# Mostramos las cuentas a las que tiene acceso (incluidas organizaciones)

Travis::Pro.accounts.each do |account|
  puts "La cuenta #{account.name} con login  #{account.login} y id #{account.id} tiene #{account.repos_count} repositorios"
end

# Parece que find_all está limitado a recuperar 25 repositorios, así que no parece la herramienta más adecuada para recuperar "todos los repositorios" de la organización:

# foo = Travis::Pro::Repository.find_all(owner_name: 'POO1819')
# puts "Repositorios recuperados: #{foo.count}"
# foo.each { |repository| puts "#{repository.slug} #{repository.last_build_state}" }

# Creamos un fichero sobre el que también escribiremos la salida de este programa


mode = "w"
file = File.open(cuasi, mode)

# file.close

# Iteramos sobre el vector de prácticas y fechas límite:

repos_fechas.each do |repository| 
	
	# Generamos el nombre del repositorio con la organización, el nombre de la práctica y la cuenta del estudiante: 
	slug = organization + '/' + repository[0] + '-' + cuasi
	
	puts "\n"
	puts "COMPROBANDO repositorio: https://github.com/#{slug}\n"
	puts "Resultados compilación : https://travis-ci.com/#{slug}"


	file.write ("\n")
	file.write "COMPROBANDO repositorio: https://github.com/#{slug}\n"
	file.write "Resultados compilación : https://travis-ci.com/#{slug}"

	# cuidado, si find no encuentra nada, porque el estudiante no ha hecho la práctica, lanza una excepción; mirar el "raise" abajo.
	begin
		# Recupera
		rep =  Travis::Pro::Repository.find(slug)
		# puts "Repositorio #{rep.name}: "
		# Mostramos las características principales del último build:
		puts "Status de su último build:" 
		puts "- Número de builds: #{rep.last_build_number}" 
		puts "- Estado          : #{rep.last_build_state}" 
		puts "- Build start     : #{rep.last_build_started_at}"
		puts "- Build finished  : #{rep.last_build_finished_at}"
		puts "- Fecha commit    : #{rep.last_build.commit.committed_at}"
		puts "- Fecha entrega   : #{repository[1]}"
		if (rep.last_build.commit.committed_at.nil?)
			puts "- Plazo cumplido  : fecha commit no disponible"
		else  
			puts "- Plazo cumplido  : #{rep.last_build.commit.committed_at < repository[1]}"
		end
		# Volcamos al fichero de texto:
		file.write "\n"
		file.write "Status de su último build: \n"
		file.write "- Número de builds: #{rep.last_build_number} \n"
		file.write "- Estado          : #{rep.last_build_state} \n"
		file.write "- Build start     : #{rep.last_build_started_at} \n"
		file.write "- Build finished  : #{rep.last_build_finished_at} \n"
		file.write "- Fecha commit    : #{rep.last_build.commit.committed_at} \n"
		file.write "- Fecha entrega   : #{repository[1]} \n"
                if (rep.last_build.commit.committed_at.nil?)
			file.write "- Plazo cumplido  : fecha commit no disponible \n"
                else
			file.write "- Plazo cumplido  : #{rep.last_build.commit.committed_at < repository[1]} \n"
                end
		
		# Algunos detalles adicionales que omitimos:
		# puts "- Autor           : #{rep.last_build.commit.author_name}"
   		# puts "- Commiter        : #{rep.last_build.commit.committer_name}"
 		# puts "- Commiter_email  : #{rep.last_build.commit.committer_name}"
   		# puts "- email           : #{rep.last_build.commit.author_email}"
		# puts "- rama            : #{rep.last_build.commit.branch}"
   		# puts "- asunto          : #{rep.last_build.commit.subject}"
		# puts "- mensaje         : #{rep.last_build.commit.message}"


		# build = rep.builds.detect { |b| b.failed? || b.errored? }
		
		# Buscamos un tag de nombre tagentrega en el repositorio del estudiante, si existe, mostramos los valores de ese commit:

		build = rep.builds.detect { |b| b.branch_info == tagentrega }
		if (build.nil?)
			puts "No hay un tag de nombre entrega"
		else
			puts "El estudiante ha generado un tag de nombre entrega:"
			puts "- Número de build : #{build.number}"
			puts "- Estado          : #{build.state}"
			puts "- Build start     : #{build.started_at}"
			puts "- Build finished  : #{build.finished_at}"
			puts "- Fecha commit    : #{build.commit.committed_at}"
			puts "- Fecha entrega   : #{repository[1]}"
			if (build.commit.committed_at.nil?)
			puts "- Plazo cumplido  : fecha commit no disponible"
			else  
				puts "- Plazo cumplido  : #{build.commit.committed_at < repository[1]}"
			end
		end

		if (build.nil?)
			file.write "No hay un tag de nombre entrega \n"
                else
			file.write "El estudiante ha generado un tag de nombre entrega: \n"
			file.write "- Número de build : #{build.number} \n"
			file.write "- Estado          : #{build.state} \n"
			file.write "- Build start     : #{build.started_at} \n"
			file.write "- Build finished  : #{build.finished_at} \n"
			file.write "- Fecha commit    : #{build.commit.committed_at} \n"
			file.write  "- Fecha entrega   : #{repository[1]} \n"
                        if (build.commit.committed_at.nil?)
				file.write "- Plazo cumplido  : fecha commit no disponible \n"
                        else
				file.write "- Plazo cumplido  : #{build.commit.committed_at < repository[1]} \n"
                        end

			# Algunos detalles adicionales que omitimos:
			# puts "- Autor           : #{build.commit.author_name}"
   			# puts "- Commiter        : #{build.commit.committer_name}"
 			# puts "- Commiter_email  : #{build.commit.committer_name}"
   			# puts "- email           : #{build.commit.author_email}"
			# puts "- rama            : #{build.commit.branch}"
   			# puts "- asunto          : #{build.commit.subject}"
			# puts "- mensaje         : #{build.commit.message}"
		end
	rescue
		puts "Repositorio #{slug} no encontrado." 
		
		file.write "Repositorio #{slug} no encontrado. \n"
	end
	puts "\n"

	file.write "\n"
end
