/**
* Name: scenario2
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model scenario2

/* Insert your model definition here */

global {
	float step <- 0.3 #s;
	shape_file bound_shapefile <- shape_file("../includes/Place de Terreaux/bound.shp");
	shape_file building_shapefile <- shape_file("../includes/Place de Terreaux/polygons.shp");
	shape_file init_space_shapefile <- shape_file("../includes/Place de Terreaux/exit_space.shp");
	shape_file center_shapefile <- shape_file("../includes/Place de Terreaux/center.shp");
	
	shape_file free_spaces_shape_file <- shape_file("../includes/free spaces.shp");
	shape_file open_area_shape_file <- shape_file("../includes/open area.shp");
	shape_file pedestrian_paths_shape_file <- shape_file("../includes/pedestrian paths.shp");
	
	geometry shape <- envelope(bound_shapefile);
	geometry open_area;
	geometry center_area;
	graph network;
	
	// pedestrian parameters
	bool display_free_space <- false parameter: true;
	bool display_force <- false parameter: true;
	bool display_target <- false parameter: true;
	bool display_circle_min_dist <- true parameter: true;
	
	float P_shoulder_length <- 0.8 parameter: true;
	float P_proba_detour <- 0.5 parameter: true ;
	bool P_avoid_other <- true parameter: true ;
	float P_obstacle_consideration_distance <- 3.0 parameter: true ;
	float P_pedestrian_consideration_distance <- 3.0 parameter: true ;
	float P_tolerance_target <- 0.1 parameter: true;
	bool P_use_geometry_target <- true parameter: true;
	
	string P_model_type <- "simple" among: ["simple", "advanced"] parameter: true ; 
	
	float P_A_pedestrian_SFM_advanced parameter: true <- 0.16 category: "SFM advanced" ;
	float P_A_obstacles_SFM_advanced parameter: true <- 1.9 category: "SFM advanced" ;
	float P_B_pedestrian_SFM_advanced parameter: true <- 3.0 category: "SFM advanced" ;
	float P_B_obstacles_SFM_advanced parameter: true <- 3.0 category: "SFM advanced" ;
	float P_relaxion_SFM_advanced  parameter: true <- 0.5 category: "SFM advanced" ;
	float P_gama_SFM_advanced parameter: true <- 0.35 category: "SFM advanced" ;
	float P_lambda_SFM_advanced <- 0.1 parameter: true category: "SFM advanced" ;
	float P_minimal_distance_advanced <- 0.25 parameter: true category: "SFM advanced" ;
	
	float P_n_prime_SFM_simple parameter: true <- 3.0 category: "SFM simple" ;
	float P_n_SFM_simple parameter: true <- 2.0 category: "SFM simple" ;
	float P_lambda_SFM_simple <- 2.0 parameter: true category: "SFM simple" ;
	float P_gama_SFM_simple parameter: true <- 0.35 category: "SFM simple" ;
	float P_relaxion_SFM_simple parameter: true <- 0.54 category: "SFM simple" ;
	float P_A_pedestrian_SFM_simple parameter: true <- 4.5category: "SFM simple" ;
	
	init {
		create building from: building_shapefile;
		create init_space from: init_space_shapefile;
		create center from: center_shapefile {
			building frontaint <- first(building where (each.name = 'Fontaine Bartholdi'));
			center_area <- shape - (frontaint + 0.5);
		}
		
		open_area <- first(open_area_shape_file.contents);
		
		create pedestrian_path from: pedestrian_paths_shape_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			free_space <- fs first_with (each covers shape); 
			if free_space = nil {
				free_space <- shape + 0.5;
			}
		}
		
		network <- as_edge_graph(pedestrian_path);
		
		create people number: 1000 {
			location <- any_location_in(one_of(center_area));
			my_target <- any_location_in(one_of(init_space));
			
			obstacle_consideration_distance <-P_obstacle_consideration_distance;
			pedestrian_consideration_distance <-P_pedestrian_consideration_distance;
			shoulder_length <- P_shoulder_length;
			avoid_other <- P_avoid_other;
			proba_detour <- P_proba_detour;
			
			use_geometry_waypoint <- P_use_geometry_target;
			tolerance_waypoint<- P_tolerance_target;
			pedestrian_species <- [people];
			obstacle_species<-[building];
			
			pedestrian_model <- P_model_type;
			
		
			if (pedestrian_model = "simple") {
				A_pedestrians_SFM <- P_A_pedestrian_SFM_simple;
				relaxion_SFM <- P_relaxion_SFM_simple;
				gama_SFM <- P_gama_SFM_simple;
				lambda_SFM <- P_lambda_SFM_simple;
				n_prime_SFM <- P_n_prime_SFM_simple;
				n_SFM <- P_n_SFM_simple;
			} else {
				A_pedestrians_SFM <- P_A_pedestrian_SFM_advanced;
				A_obstacles_SFM <- P_A_obstacles_SFM_advanced;
				B_pedestrians_SFM <- P_B_pedestrian_SFM_advanced;
				B_obstacles_SFM <- P_B_obstacles_SFM_advanced;
				relaxion_SFM <- P_relaxion_SFM_advanced;
				gama_SFM <- P_gama_SFM_advanced;
				lambda_SFM <- P_lambda_SFM_advanced;
				minimal_distance <- P_minimal_distance_advanced;
			}
			
			do compute_virtual_path pedestrian_graph:network target: my_target;
			
		}
	
	}
}

species building {
	aspect default {
		draw shape color: #grey;
	}
}

species center {
	aspect default {
		draw shape color: #grey;
	}
}

species init_space {
	aspect default {
		draw shape color: #green;
	}
}

species people skills: [pedestrian]{
	rgb color <- rnd_color(255);
	float speed <- gauss(5,1.5) #km/#h min: 2 #km/#h;
	point my_target;
	
	reflex move_out {
//		do walk_to target: my_target bounds: open_area;

		do walk;
		
		if (distance_to(location, my_target) < 1.0 or final_waypoint = nil) {
			do die;
		}
	}
	
	aspect default {
		draw circle(P_shoulder_length / 2) color: #blue;
	}
}

species pedestrian_path skills: [pedestrian_road]{
	aspect default { 
		draw shape  color: #gray;
	}
	aspect free_area_aspect {
		if(free_space != nil) {
			draw free_space color: #lightpink border: #black;
		}
		
	}
}

experiment exp type: gui {
	output {
		display place_de_terreaux {
			species building refresh: false;
//			species pedestrian_path refresh: false;
			species people;
		}
	}
}