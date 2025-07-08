extends Node

@export var silly_names := [
	# Disney characters
	'Donald', 'Daisy', 'Goofy', 'Pluto', 'Mickey', 'Minnie',
	'Buzz', 'Woody', 'Bo Peep', 'Grumpy', 'Bashful', 'Doc',
	'Sleepy', 'Sneezy', 'Dopey', 'Happy', 'Snow White',
	'Cinderella', 'Aurora', 'Rapunzel', 'Little Mermaid', 'Ariel',
	'Sebastian', 'Flounder', 'Merida', 'Phillip', 'Eric', 'Daisy',
	'Chip', 'Dale', 'Robin Hood', 'Heimlich', 'Gadget', 'Perdita',
	'Pongo', 'Genie', 'Aladdin', 'Jasmine', 'Abu', 'Iago',
	'Rajah', 'Alice', 'Anastasia', 'Marie', 'Toulouse', 'Berlioz',
	'Duchess', 'Bambi', 'Thumper', 'Belle', 'Beast', 'Lumière',
	'Cogsworth', 'Mrs. Potts', 'Gaston', 'Flik', 'Gus', 'Jaq',
	'Drizella', 'Ursula', 'Dumbo', 'Kuzco', 'Kronk', 'Pacha',
	'Yzma', 'Giselle', 'Nemo', 'Dory', 'Crush', 'Bruce', 'Hank',
	'Destiny', 'Bailey', 'Pearl', 'Copper', 'Todd', 'Elsa',
	'Anna', 'Olaf', 'Sven', 'Kristoff', 'Max', 'Hercules', 'Meg',
	'Pegasus', 'Scrat', 'Esmeralda', 'Quasimodo', 'Hugo', 'Sid',
	'Diego', 'Manny', 'Dash', 'Violet', 'Jack Jack', 'Indiana Jones',
	'Marion', 'Joy', 'Baloo', 'Mowgli', 'King Louie',
	'Kaa', 'Bagheera', 'Shere Khan', 'Lady', 'Tramp', 'Lilo',
	'Stitch', 'Moana', 'Maui', 'Simba', 'Pumbaa', 'Timon',
	'Rafiki', 'Nala', 'Zazu', 'Mufasa', 'Shenzi', 'Scar',
	'Scuttle', 'King Triton', 'Burt', 'Mary Poppins', 'Oswald',
	'Bob Cratchit', 'Jacob Marley', 'Ebenezer Scrooge', 'Tiny Tim',
	'Pua', 'Hei Hei', 'Mike Wazowski', 'Sulley', 'Randall', 'Celia',
	'Mater',
	'Roz', 'Boo', 'Mulan', 'Mushu', 'Cri-Kee', 'Li Shang', 'Ping',
	'Shan Yu', 'Kermit', 'Fozzie Bear', 'Miss Piggy', 'Sweedish Chef',
	'Gonzo', 'Animal', 'Rowlf', 'Jack Skellington', 'Jack Sparrow',
	'Sally', 'Zero', 'Dr. Finkelstein', 'Oogie Boogie', 'Barley',
	'Manticore', 'Tinker Bell', 'Peter Pan', 'Wendy', 'Nana',
	'John', 'Michael', 'Mr. Smee', 'Captain Hook', 'Phineas',
	'Ferb', 'Perry the Platypus', 'Jiminy Cricket', 'Pinocchio',
	'Pistachio', 'Figaro', 'Geppetto', 'Blue Fairy', 'Monstro',
	'Barbossa', 'Davy Jones', 'Elizabeth Swann', 'Pocahontas',
	'Flit', 'Meeko', 'Percy', 'Governor Ratcliffe', 'John Smith',
	'Grandma Willow', 'Tiana', 'Louis', 'Ray', 'Charlotte La Bouff',
	'Mama Odie', 'Prince Naveen', 'Dr. Facilier', 'Remy',
	'Alfredo Linguini', 'Auguste Gusteau', 'Anton Ego', 'Chef Skinner',
	'Raya', 'Tuk Tuk', 'Namaari', 'Sisu', 'Monterey Jack',
	'Bernard', 'Bianca', 'Madame Medusa', 'Maid Marian',
	'Lady Kluck', 'Little John', 'Sir Hiss', 'Prince John',
	'Flora', 'Fauna', 'Merriweather', 'Maleficent', 'Briar Rose',
	'Arthur', 'Archimedes', 'Merlin', 'Madam Mim', 'Pascal',
	'Flynn Rider', 'Maximus', 'Mother Gothel', 'Jessie',
	'Bullseye', 'Rex', 'Ham', 'Zurg', 'Winnie the Pooh', 'Tigger',
	'Rabbit', 'Eeyore', 'Piglet', 'Vanellope', 'Ralph', 'Yesss',
	'Fix-It Felix, Jr.', 'Calhoun', 'King Candy', 'Taffyta', 'Nick Wilde',
	'Judy Hopps', 'Clawhauser', 'Finnick', 'Flash', 'Gazelle',
	'Baymax', 'Cruella De Vil', 'Wreck-It Ralph', 'Figment',
	'Darkwing Duck',
	# Universal
	'Mario', 'Luigi', 'Princess Peach', 'Bowser', 'Yoshi', 'Toad',
	'Wario', 'Daisy', 'Toadette', 'Minion',
	'Shrek', 'Donkey', 'Fiona', 'Puss in Boots', 'Kitty Softpaws',
	'Lord Farquaad',
	'Marty McFly', 'Doc Brown', 'E.T.',
	'Popeye', 'Casper',
	# Pokémon
	'Pikachu', 'Bulbasaur', 'Jigglypuff', 'Snorlax', 'Charizard',
	'Meowth', 'Psyduck', 'Charmander', 'Squirtle', 'Mewtwo', 'Eevee',
	'Gengar',
	# Hello Kitty (Sanrio)
	'Hello Kitty', 'Keroppi', 'Badtz-Maru', 'Chococat', 'Aggretsuko',
	# Barbie
	'Barbie', 'Ken', 'Skipper', 'Midge',
	# Transformers
	'Optimus Prime', 'Bumblebee', 'Megatron', 'Starscream', 'Soundwave', 'Ironhide',
	# Harry Potter
	'Harry Potter', 'Hermione Granger', 'Ron Weasley', 'Albus Dumbledore', 'Severus Snape',
	# Star Wars
	'Luke Skywalker', 'Darth Vader', 'Chewbacca', 'Yoda', 'Han Solo', 'Obi-Wan Kenobie', 'Anakin',
	'Princess Leia', 'Darth Maul', 'Andor', 'R2-D2', 'C-3PO', 'Boba Fett',
	'Rey', 'Kylo Ren',
	# Marvel
	'Spider-Man', 'Iron Man', 'Wolverine', 'Groot', 'Captain America', 'Thor',
	'Hulk', 'Black Widow', 'Doctor Strange', 'Rocket',
	# Sega
	'Sonic', 'Tails', 'Knuckles', 'Amy Rose', 'Shadow', 'Dr. Eggman', 'Dr. Robotnik',
	'Metal', 'Rouge',
	# Nintendo
	# Legend of Zelda
	'Link', 'Zelda', 'Ganondorf', 'Tingle', 'Navi', 'Midna', 'Impa', 'Sheik',
	 #Warner Bros.
	# Looney Tunes
	'Bugs Bunny', 'Daffy Duck', 'Porky Pig', 'Elmer Fudd', 'Yosemite Sam', 'Tweety',
	'Sylvester', 'Marvin', 'Wile E. Coyote', 'Road Runner',
	# Scooby-Doo
	'Scooby-Doo', 'Shaggy', 'Velma', 'Daphne', 'Fred', 'Scrappy',
	# Nickelodeon
	# SpongeBob SquarePants
	'SpongeBob', 'Patrick Star', 'Squidward', 'Mr. Krabs', 'Plankton', 'Sandy',
	# DreamWorks
	# Madagascar
	'Alex', 'Marty', 'Melman', 'Gloria', 'King Julien',
	# Kung Fu Panda
	'Po', 'Master Shifu', 'Tai Lung', 'Tigress', 'Crane',
	# Peanuts (Charles Schulz)
	'Charlie Brown', 'Snoopy', 'Woodstock', 'Linus', 'Lucy', 'Pigpen', 'Schroeder',
	'Peppermint Patty',
	# Konami
	# Castlevania
	'Simon Belmont', 'Dracula', 'Alucard', 'Richter',
	# Cartoon Network
	# The Powerpuff Girls
	'Blossom', 'Bubbles', 'Buttercup', 'Mojo Jojo',
	# DC Comics
	'Batman', 'Superman', 'Wonder Woman', 'The Flash', 'Aquaman',
	'Harley Quinn', 'Lex Luthor', 'Robin', 'Catwoman', # 'Joker'
	# Family favorites
	'Leafeon', 'Flareon', 'Korok',
	'Nikke', 'Kafka Hibino', 'Reno Ichikawa', 'Kasumi Miwa', 'Watanabe You',
]
