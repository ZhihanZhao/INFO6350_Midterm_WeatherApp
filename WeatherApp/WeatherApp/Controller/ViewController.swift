//
//  ViewController.swift
//  WeatherApp
//
//  Created by 赵芷涵 on 10/29/21.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON
import SwiftSpinner
import PromiseKit

class ViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {
    
    let arr = ["Seattle WA, USA 54 °F", "Delhi DL, India, 75°F"]
    
    var arrCityInfo: [CityInfo] = [CityInfo]()
    var arrCurrentWeather : [CurrentWeather] = [CurrentWeather]()
    
    @IBOutlet weak var tblView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblView.delegate = self
        tblView.dataSource = self
        loadCurrentConditions()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrCurrentWeather.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("TableViewCell", owner: self, options: nil)?.first as! WeatherTableViewCell
//        cell.lblCityName.text = "\(arrCurrentWeather[indexPath.row].cityInfoName )"
//        cell.lblTemp.text = "\(arrCurrentWeather[indexPath.row].temp )"
//        if(arrCurrentWeather[indexPath.row].weatherText.lowercased().contains("sunny")){
//            cell.imageWeather.image = UIImage(named: "sunny")
//        }else if(arrCurrentWeather[indexPath.row].weatherText.lowercased().contains("cloudy")){
//            cell.imageWeather.image = UIImage(named: "cloudy")
//        }else{
//            cell.imageWeather.image = UIImage(named: "rainny")
//        }
        
        return cell
    }
    
    func loadCurrentConditions(){
        do{
            let realm = try Realm()
            let cities = realm.objects(CityInfo.self)
            self.arrCityInfo.removeAll()
            getAllCurrentWeather(Array(cities)).done { currentWeather in
                self.arrCurrentWeather = currentWeather
                self.tblView.reloadData()
            }
            .catch { error in
               print(error)
            }
       }catch{
           print("Error in reading Database \(error)")
       }
                
        
    }
    
    func getAllCurrentWeather(_ cities: [CityInfo] ) -> Promise<[CurrentWeather]> {
            var promises: [Promise< CurrentWeather>] = []
            
        for i in 0 ..< cities.count {
                promises.append( getCurrentWeather(cities[i].locationKey, cities[i].cityName) )
            }
            
            return when(fulfilled: promises)
            
        }
    
    func getCurrentWeather(_ cityKey : String, _ cityName : String) -> Promise<CurrentWeather>{
            return Promise<CurrentWeather> { seal -> Void in
                let url = "\(currentWeatherURL)\(cityKey)?apikey=\(apiKey)" // build URL for current weather here
                Alamofire.request(url).responseJSON { response in
                    
                    if response.error != nil {
                        seal.reject(response.error!)
                    }
                    
                    let autoCompleteJSON : [JSON] = JSON(response.value).arrayValue
                    let WeatherInfo = autoCompleteJSON[0]
                    let currentWeather = CurrentWeather()
                    currentWeather.cityInfoName = cityName
                    currentWeather.cityKey = cityKey
                    currentWeather.epochTime = WeatherInfo["EpochTime"].intValue
                    currentWeather.isDayTime = WeatherInfo["IsDayTime"].boolValue
                    currentWeather.temp = WeatherInfo["Temperature"]["Metric"]["Value"].intValue
                    currentWeather.weatherText = WeatherInfo["WeatherText"].stringValue
                  
                    
                    seal.fulfill(currentWeather)
                    
                }
            }
    }


}

