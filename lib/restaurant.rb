require "colorize"

class Restaurant < ActiveRecord::Base
  has_many :reviews
  has_many :users, through: :reviews
  belongs_to :cuisine

  #Method for searching restaurants by name
  def self.search_by_name(user)
    puts "What is the name of restaurant you are looking for?" 
    input = STDIN.gets.chomp
    result = all.where(name: input)
    print_result(result)
    puts "\n"
    puts "Enter the number of the restaurant you would like to expand details on:"
    num_entry = STDIN.gets.chomp.to_i
    if num_entry > result.count || num_entry == 0
      puts "Invalid entry, try again."
      Restaurant.search_by_name(user)
    end
    result[num_entry - 1].expand_details(user)
    result
  end

  #Methods for searching restaurants by neighborhood
  def self.uniq_locations
    Restaurant.all.map(&:neighborhood).uniq.sort
  end
  
  def self.uniq_locations_with_index
    uniq_locations.each_with_index { |neighborhood, index| 
      puts "#{index + 1}: #{neighborhood}"
    }
    puts "\n"
  end
  
  def self.search_by_neighborhood(user)
    puts "Choose a location from the list below. Enter a number."
    uniq_locations_with_index
    input = STDIN.gets.chomp.to_i
    if input > uniq_locations.count || input == 0
      puts "Invalid entry, try again."
      Restaurant.search_by_neighborhood(user)
    end
    puts "========="
    result = all.where(neighborhood: uniq_locations[input - 1])
    print_result(result)
    puts "\n"
    puts "Enter the number of the restaurant you would like to expand details on:"
    num_entry = STDIN.gets.chomp.to_i
    if num_entry > result.count || num_entry == 0
      puts "Invalid entry, try again."
      Restaurant.search_by_neighborhood(user)
    end
    result[num_entry - 1].expand_details(user)
    result
  end
  
  def self.find_random_by_neighborhood(user)
    puts "Choose a location from the list below. Enter a number."
    uniq_locations_with_index
    input = STDIN.gets.chomp.to_i
    if input > uniq_locations.count || input == 0
      puts "Invalid entry, try again."
      Restaurant.find_random_by_neighborhood(user)
    end
    puts "========="
    list = all.where(neighborhood: uniq_locations[input - 1])
    result = [list.sample]
    print_result(result)
    puts "\n"

    result[0].expand_details(user)
    result
  end
  
  def self.print_result(restaurants)
    case restaurants.count
    when 0
      puts "There is no restaurant matched."
    else
      restaurants.each_with_index { |restaurant, index|
        puts index + 1
        restaurant.show_details
      }
    end
  end

  def show_details
    credit_card ? cc = "Yes" : cc = "No"
    reservations ? rsv = "Yes" : rsv = "No"
    puts "#{name}"
    puts "Address: #{address}"
    puts "Website: #{website}"
    puts "Yelp page: #{yelp_page}"
    puts "Business hour: #{hours}"
    puts "Accept credit cards?: #{cc}"
    puts "Accept reservations?: #{rsv}"
  end

  def expand_details(user)
    puts "Would you like to open this restaurant's page? (Y/N)"
    entry = STDIN.gets.chomp
    case entry
    when "Y" || "y"
      self.restaurant_page(user)
    when "N" || "n"
      puts "No problem, we'll return you to the main menu!"
      CLI.restaurant_search_menu(user)
    else
      puts "Sorry we didn't catch that, please try again."
      self.expand_details(user)
    end
    
  end

  def restaurant_page(user)
    puts "======================================================================================================"
    puts "#{self.name} || #{self.address} || #{self.phone}".yellow.bold
    puts "======================================================================================================"
    puts "We're rated an average of #{self.average_star_count} out of 5 stars, based on #{self.reviews.count} review(s)!"
    puts "======================================================================================================"
    puts "\n"
    puts "Visit us at #{self.website}".colorize(:light_blue)
    puts "Find us on Yelp #{self.yelp_page}".colorize(:light_blue)
    puts "======================================================================================================"
    puts "Feeling hundry? Find something on our menu, it's all good!"
    puts "#{self.menu_link}"
    puts "\n"
    puts "Accept Credit Cards? #{self.credit_card ? cc = "Yes" : cc = "No"}   ||    Take Reservations? #{self.reservations ? rsv = "Yes" : rsv = "No"}"
    puts "======================================================================================================"
    puts "Want to know more about us?"
    puts "#{self.about}"
    puts "======================================================================================================"
    puts "Check out reviews from customers:"
    puts "======================================================================================================"
    self.pretty_display_reviews
    puts "Have you visited us recently? Give us some feedback!"
    puts "\n"
    puts "If you would like to create a review for this restaurant, please enter 'Y' for yes or 'N' for no."
    start_new_review = STDIN.gets.chomp

    case start_new_review
    when "Y"
      puts "Great, please type number of stars you would rate your last visit in integer format:"
      star_input = STDIN.gets.chomp
      puts "Okay, time to be descriptive, please give details:"
      desc_input = STDIN.gets.chomp
      review = Review.create(star_rating: star_input.to_i, desc: desc_input, user_id: user.id, restaurant_id: self.id)
      puts "Thanks for reviewing #{self.name}, we look forward to reading it!"
      puts "\n"
      puts "Here's what your review looks like:"
      review.nice_display
      puts "To update this review, you will need to go to the main menu and choose menu option '2'."
      puts "\n"
      puts "Would you like to go back to the main menu? (Y/N)"
      go_back_1 = STDIN.gets.chomp
      case go_back_1
      when "Y"
        puts "Great, we'll send you back to the main menu."
        CLI.main_menu(user)
      when "N"
        puts "No problem, we'll see you again another time."
        exit
      end
    when "N"
      puts "No problem! You should come by sometime and we'll work hard to make your visit memorable."
      puts "\n"
      puts "Would you like to go back to the main menu? (Y/N)"
      go_back_2 = STDIN.gets.chomp
      case go_back_2
      when "Y"
        puts "Great, we'll send you back to the main menu."
        CLI.main_menu(user)
      when "N"
        puts "No problem, we'll see you again another time."
        exit
      end
    else
      puts "Sorry invalid input, please try again".red
      puts "\n"
      self.restaurant_page(user)
    end
  end

  def average_star_count
    return 0 if reviews.count == 0

    reviews.inject(0) { |sum, review| 
      sum + review.star_rating
    }.to_f / reviews.count
  end

  #Methods for recommendation of restaurants by cuisine
  def self.uniq_cuisines
    Restaurant.all.map(&:cuisine).uniq.sort_by(&:name)
  end

  def self.uniq_cuisines_with_index
    uniq_cuisines.each_with_index { |cuisine, index| 
      puts "#{index + 1}: #{cuisine.name}"
    }
    puts "\n"
  end

  def self.recommendations_by_cuisine(user)
    puts "Choose a cuisine from the list below. Enter a number."
    uniq_cuisines_with_index
    input = STDIN.gets.chomp.to_i
    if input > uniq_cuisines.count || input == 0
      puts "Invalid input, please try again."
      Restaurant.recommendations_by_cuisine(user)
    end
    puts "========="
    result = all.where(cuisine_id: uniq_cuisines[input - 1].id)
      .select {|r| r.average_star_count >= 4 }
      .sort_by { |r| r.average_star_count }
      .reverse
      .take(5)
    print_result(result)
    puts "\n"
    puts "Enter the number of the restaurant you would like to expand details on:"
    num_entry = STDIN.gets.chomp.to_i
    if num_entry > result.count
      puts "Invalid entry, try again."
      Restaurant.recommendations_by_cuisine(user)
    end
    result[num_entry - 1].expand_details(user)
    result
  end

  def pretty_display_reviews
    self.reviews.each_with_index do |review, index|
      puts "\n"
      puts "#{index + 1}".yellow
      puts "#{review.stars(review.star_rating)}created on: #{review.created_at}"
      puts "======================================================================="
      puts "'#{review.desc}'"
      puts "\n"
      puts "by #{review.user.first_name} #{review.user.last_name.first}.".italic
      puts "======================================================================="
    end
  end

end